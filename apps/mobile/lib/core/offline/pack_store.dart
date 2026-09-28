import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/generated/export.dart';
import '../db/app_database.dart';

/// `subject:<id>` or `teacher_track:<id>`, the lease key of a pack's scope.
String scopeKeyOf(String scopeType, String? subjectId, String? teacherTrackId) =>
    scopeType == 'teacher_track' ? 'teacher_track:$teacherTrackId' : 'subject:$subjectId';

String packScopeKey(OfflinePackRow p) => scopeKeyOf(p.scopeType, p.subjectId, p.teacherTrackId);

/// Pack rows, items, image files and leases in the local database (spec §22).
class PackStore {
  PackStore(this.db);

  final AppDatabase db;
  static const serverTimeKey = 'offline.server_time';
  static const wifiOnlyKey = 'settings.offline_wifi_only';
  static const autoUpdateKey = 'settings.offline_auto_update';

  // ---- packs ----

  Stream<List<OfflinePackRow>> watchPacks() => (db.select(
    db.offlinePacks,
  )..orderBy([(t) => OrderingTerm.asc(t.scopeTitle), (t) => OrderingTerm.asc(t.titleAr)])).watch();

  Future<List<OfflinePackRow>> packs() => db.select(db.offlinePacks).get();

  Future<OfflinePackRow?> pack(String key) =>
      (db.select(db.offlinePacks)..where((t) => t.packKey.equals(key))).getSingleOrNull();

  Future<void> savePack(OfflinePacksCompanion row) => db.into(db.offlinePacks).insertOnConflictUpdate(row);

  Future<void> updatePack(String key, OfflinePacksCompanion changes) =>
      (db.update(db.offlinePacks)..where((t) => t.packKey.equals(key))).write(changes);

  /// Removes a pack and returns the image files to delete.
  Future<List<String>> deletePack(String key) => db.transaction(() async {
    final files = await (db.select(db.offlineFiles)..where((t) => t.packKey.equals(key))).get();
    await (db.delete(db.offlineFiles)..where((t) => t.packKey.equals(key))).go();
    await (db.delete(db.offlineItems)..where((t) => t.packKey.equals(key))).go();
    await (db.delete(db.offlinePacks)..where((t) => t.packKey.equals(key))).go();
    return [for (final f in files) f.path];
  });

  // ---- items ----

  Future<Map<String, OfflineItemRow>> itemsOf(String key) async => {
    for (final r in await (db.select(db.offlineItems)..where((t) => t.packKey.equals(key))).get()) r.itemId: r,
  };

  Future<void> putItems(String key, List<OfflineItem> items) => db.batch((b) {
    for (final i in items) {
      final free = i.question?.isFree ?? i.deck?.isFree ?? i.quiz?.isFree ?? true;
      final body = i.question?.toJson() ?? i.deck?.toJson() ?? i.card?.toJson() ?? i.quiz?.toJson();
      b.insert(
        db.offlineItems,
        OfflineItemsCompanion.insert(
          packKey: key,
          itemId: i.id,
          type: i.type.json!,
          version: i.version,
          isFree: free,
          json: jsonEncode(body),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  });

  /// Cards take the deck's free flag (their own items carry none).
  Future<void> markCardsFree(String key, Map<String, bool> freeByDeck) async {
    final cards = await (db.select(db.offlineItems)..where((t) => t.packKey.equals(key) & t.type.equals('card'))).get();
    for (final c in cards) {
      final deckId = (jsonDecode(c.json) as Map<String, Object?>)['deckId'] as String?;
      final free = freeByDeck[deckId] ?? false;
      if (free != c.isFree) {
        await (db.update(db.offlineItems)..where((t) => t.packKey.equals(key) & t.itemId.equals(c.itemId))).write(
          OfflineItemsCompanion(isFree: Value(free)),
        );
      }
    }
  }

  Future<void> removeItems(String key, Iterable<String> ids) {
    final list = ids.toList();
    if (list.isEmpty) return Future.value();
    return (db.delete(db.offlineItems)..where((t) => t.packKey.equals(key) & t.itemId.isIn(list))).go();
  }

  /// Items of one type across ready packs (the caller filters by lease).
  Future<List<(OfflinePackRow, OfflineItemRow)>> itemsOfType(String type) async {
    final rows = await (db.select(db.offlineItems).join([
      innerJoin(db.offlinePacks, db.offlinePacks.packKey.equalsExp(db.offlineItems.packKey)),
    ])..where(db.offlineItems.type.equals(type) & db.offlinePacks.status.equals('ready'))).get();
    return [for (final r in rows) (r.readTable(db.offlinePacks), r.readTable(db.offlineItems))];
  }

  Future<List<(OfflinePackRow, OfflineItemRow)>> itemById(String id) async {
    final rows = await (db.select(db.offlineItems).join([
      innerJoin(db.offlinePacks, db.offlinePacks.packKey.equalsExp(db.offlineItems.packKey)),
    ])..where(db.offlineItems.itemId.equals(id) & db.offlinePacks.status.equals('ready'))).get();
    return [for (final r in rows) (r.readTable(db.offlinePacks), r.readTable(db.offlineItems))];
  }

  // ---- files ----

  Future<OfflineFileRow?> file(String key, String mediaId) =>
      (db.select(db.offlineFiles)..where((t) => t.packKey.equals(key) & t.mediaId.equals(mediaId))).getSingleOrNull();

  Future<OfflineFileRow?> anyFile(String mediaId) =>
      (db.select(db.offlineFiles)
            ..where((t) => t.mediaId.equals(mediaId))
            ..limit(1))
          .getSingleOrNull();

  Future<List<OfflineFileRow>> filesOf(String key) =>
      (db.select(db.offlineFiles)..where((t) => t.packKey.equals(key))).get();

  Future<void> putFile(OfflineFilesCompanion row) => db.into(db.offlineFiles).insertOnConflictUpdate(row);

  Future<void> removeFile(String key, String mediaId) =>
      (db.delete(db.offlineFiles)..where((t) => t.packKey.equals(key) & t.mediaId.equals(mediaId))).go();

  /// Whether another pack still uses this file.
  Future<bool> fileShared(String path, String exceptPack) async => (await (db.select(
    db.offlineFiles,
  )..where((t) => t.path.equals(path) & t.packKey.equals(exceptPack).not())).get()).isNotEmpty;

  // ---- leases and time ----

  Future<OfflineLeaseRow?> lease(String scopeKey) =>
      (db.select(db.offlineLeaseRows)..where((t) => t.scopeKey.equals(scopeKey))).getSingleOrNull();

  Future<List<OfflineLeaseRow>> leases() => db.select(db.offlineLeaseRows).get();

  Future<void> putLease(String scopeKey, int expiresAt, int refreshedAt) => db
      .into(db.offlineLeaseRows)
      .insertOnConflictUpdate(
        OfflineLeaseRowsCompanion.insert(scopeKey: scopeKey, expiresAt: expiresAt, refreshedAt: refreshedAt),
      );

  Future<void> deleteLease(String scopeKey) =>
      (db.delete(db.offlineLeaseRows)..where((t) => t.scopeKey.equals(scopeKey))).go();

  /// The latest server time seen (clock protection, §22.4).
  Future<int?> serverTime() async => int.tryParse(await db.getValue(serverTimeKey) ?? '');
  Future<void> setServerTime(int ms) async {
    final known = await serverTime();
    if (known == null || ms > known) await db.setValue(serverTimeKey, '$ms');
  }

  // ---- settings (§22.2) ----

  Future<bool> wifiOnly() async => (await db.getValue(wifiOnlyKey)) != 'false';
  Future<bool> autoUpdate() async => (await db.getValue(autoUpdateKey)) != 'false';
  Future<void> setWifiOnly(bool v) => db.setValue(wifiOnlyKey, '$v');
  Future<void> setAutoUpdate(bool v) => db.setValue(autoUpdateKey, '$v');
}
