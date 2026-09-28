import 'dart:typed_data';

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:drift/drift.dart' show Value;

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../db/app_database.dart';
import 'pack_files.dart';
import 'pack_store.dart';

/// Items fetched per request (ids travel in the query string).
const _chunk = 50;

/// Why a download stopped early.
enum DownloadStop { paused, cancelled, waitingWifi }

class DownloadStopped implements Exception {
  const DownloadStopped(this.reason);
  final DownloadStop reason;
}

/// Downloads packs (spec §22.2, §22.3): manifest first, then only new or changed items in chunks,
/// images encrypted as they arrive. Progress is saved per chunk, so an interrupted download resumes
/// where it stopped; deleted or archived items are removed.
class PackDownloader {
  PackDownloader({
    required this.client,
    required this.store,
    required this.files,
    required this.onWifi,
    required this.clock,
    this.onProgress,
  });

  final ApiClient client;
  final PackStore store;
  final PackFileStore files;

  /// Whether the device is on Wi-Fi (or another unmetered connection) now.
  final Future<bool> Function() onWifi;
  final int Function() clock;
  final void Function(String packKey)? onProgress;

  final _stop = <String, DownloadStop>{};

  void pause(String key) => _stop[key] = DownloadStop.paused;

  /// Stops and removes the pack.
  Future<void> cancel(String key) async {
    _stop[key] = DownloadStop.cancelled;
    await remove(key);
  }

  Future<void> remove(String key) async {
    for (final path in await store.deletePack(key)) {
      if (!await store.fileShared(path, key)) await files.delete(path);
    }
  }

  /// Records the pack as queued, with what the catalog said about it.
  Future<void> enqueue(OfflinePack pack, {required OfflineScope scope, required String scopeTitle}) async {
    final existing = await store.pack(pack.packKey);
    await store.savePack(
      OfflinePacksCompanion.insert(
        packKey: pack.packKey,
        scopeType: scope.scopeType.json!,
        subjectId: Value(scope.subjectId),
        teacherTrackId: Value(scope.teacherTrackId),
        scopeTitle: scopeTitle,
        kind: pack.kind.json!,
        unitId: Value(pack.unitId),
        deckId: Value(pack.deckId),
        titleAr: pack.titleAr,
        status: existing?.status == 'ready' ? 'ready' : 'queued',
        version: Value(existing?.version),
        remoteVersion: Value(pack.version),
        premium: Value(pack.premium),
        sizeBytes: Value(pack.sizeBytes),
        downloadedBytes: Value(existing?.downloadedBytes ?? 0),
        updatedAt: existing?.updatedAt ?? clock(),
      ),
    );
  }

  /// Downloads or updates one pack. Throws [DownloadStopped] when paused, cancelled or waiting for
  /// Wi-Fi, and [ApiException] when the network fails (the pack stays resumable).
  Future<void> download(String key, {bool allowMobileData = false}) async {
    _stop.remove(key);
    final pack = await store.pack(key);
    if (pack == null) throw const ApiException('NOT_FOUND', 'العنصر غير موجود');
    if (!allowMobileData && await store.wifiOnly() && !await onWifi()) {
      await store.updatePack(key, const OfflinePacksCompanion(status: Value('waiting_wifi')));
      throw const DownloadStopped(DownloadStop.waitingWifi);
    }
    await store.updatePack(key, const OfflinePacksCompanion(status: Value('downloading')));
    try {
      await _run(key, pack);
    } on DownloadStopped catch (e) {
      if (e.reason == DownloadStop.paused) {
        await store.updatePack(key, const OfflinePacksCompanion(status: Value('paused')));
      }
      rethrow;
    } catch (_) {
      if (await store.pack(key) != null) {
        await store.updatePack(key, const OfflinePacksCompanion(status: Value('failed')));
      }
      rethrow;
    }
  }

  void _checkStop(String key) {
    final stop = _stop[key];
    if (stop != null) throw DownloadStopped(stop);
  }

  Future<void> _run(String key, OfflinePackRow pack) async {
    final manifest = await guardApi(() async => (await client.api.offline.offlineManifest(packKey: key)).data);
    final local = await store.itemsOf(key);
    final wanted = {for (final i in manifest.items) i.id: i};

    // Removed or archived on the server: delete here too (learning history is kept on the server).
    final gone = local.keys.where((id) => !wanted.containsKey(id)).toList();
    for (final id in gone) {
      if (local[id]!.type == 'card') await _dropCardImages(key, local[id]!);
    }
    await store.removeItems(key, gone);

    final changed = [
      for (final i in manifest.items)
        if (local[i.id]?.version != i.version) i.id,
    ];
    var done = 0;
    final perItem = changed.isEmpty ? 0 : pack.sizeBytes ~/ manifest.items.length;
    var downloaded = (manifest.items.length - changed.length) * perItem;
    for (var at = 0; at < changed.length; at += _chunk) {
      _checkStop(key);
      final ids = changed.sublist(at, (at + _chunk).clamp(0, changed.length));
      final page = await guardApi(
        () async => (await client.api.offline.offlineItems(packKey: key, ids: ids.join(','))).data,
      );
      for (final item in page.items) {
        final card = item.card;
        if (card != null) {
          for (final img in [card.front, card.back]) {
            await _saveImage(key, img);
            _checkStop(key);
          }
        }
      }
      await store.putItems(key, page.items);
      done += ids.length;
      downloaded += ids.length * perItem;
      await store.updatePack(key, OfflinePacksCompanion(downloadedBytes: Value(downloaded)));
      onProgress?.call(key);
    }

    // Cards take their deck's free flag, for leases (§22.4).
    final items = await store.itemsOf(key);
    await store.markCardsFree(key, {
      for (final i in items.values)
        if (i.type == 'deck') i.itemId: i.isFree,
    });
    await store.updatePack(
      key,
      OfflinePacksCompanion(
        status: const Value('ready'),
        version: Value(manifest.version),
        remoteVersion: Value(manifest.version),
        premium: Value(manifest.premium),
        normalizationVersion: Value(manifest.normalizationVersion),
        downloadedBytes: Value(pack.sizeBytes),
        updatedAt: Value(clock()),
      ),
    );
    onProgress?.call(key);
    assert(done == changed.length);
  }

  Future<void> _saveImage(String key, OfflineImage img) async {
    final existing = await store.file(key, img.mediaId);
    if (existing != null && existing.version == img.version) return;
    final shared = await store.anyFile(img.mediaId);
    var path = shared != null && shared.version == img.version ? shared.path : null;
    if (path == null) {
      final res = await guardApi(
        () => client.uploadDio.get<List<int>>(img.url, options: Options(responseType: ResponseType.bytes)),
      );
      path = await files.write('${img.mediaId}-${img.version}', Uint8List.fromList(res.data!));
    }
    await store.putFile(
      OfflineFilesCompanion.insert(
        packKey: key,
        mediaId: img.mediaId,
        version: img.version,
        path: path,
        sizeBytes: img.sizeBytes,
      ),
    );
    if (existing != null && existing.path != path && !await store.fileShared(existing.path, key)) {
      await files.delete(existing.path);
    }
  }

  Future<void> _dropCardImages(String key, OfflineItemRow row) async {
    final files = await store.filesOf(key);
    for (final f in files) {
      if (row.json.contains(f.mediaId)) {
        await store.removeFile(key, f.mediaId);
        if (!await store.fileShared(f.path, key)) await this.files.delete(f.path);
      }
    }
  }
}
