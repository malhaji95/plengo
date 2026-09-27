import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'scheduler.dart';

/// A rating kept locally until synced (spec §13.6).
class LocalReviewLog {
  const LocalReviewLog({
    required this.id,
    required this.flashcardId,
    required this.rating,
    required this.before,
    required this.after,
    required this.reviewedAt,
    this.durationMs,
    this.undone = false,
  });

  final String id;
  final String flashcardId;
  final Rating rating;
  final CardState before;
  final CardState after;
  final int reviewedAt;
  final int? durationMs;
  final bool undone;
}

/// Local SRS state in the encrypted database: card states, review logs and the sync cursor.
class SrsStore {
  SrsStore(this.db);

  final AppDatabase db;
  static const cursorKey = 'srs.cursor';

  CardState _toState(SrsCardState r) => CardState(
    state: cardStateNameFromJson(r.state),
    step: r.step,
    dueAt: r.dueAt,
    intervalDays: r.intervalDays,
    ease: r.ease,
    reps: r.reps,
    lapses: r.lapses,
    lastReviewedAt: r.lastReviewedAt,
  );

  Future<Map<String, CardState>> statesFor(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return {};
    final rows = await (db.select(db.srsCardStates)..where((t) => t.flashcardId.isIn(list))).get();
    return {for (final r in rows) r.flashcardId: _toState(r)};
  }

  Future<void> putState(String flashcardId, CardState s) => db
      .into(db.srsCardStates)
      .insertOnConflictUpdate(
        SrsCardStatesCompanion.insert(
          flashcardId: flashcardId,
          state: cardStateNameToJson(s.state),
          step: s.step,
          dueAt: s.dueAt,
          intervalDays: s.intervalDays,
          ease: s.ease,
          reps: s.reps,
          lapses: s.lapses,
          lastReviewedAt: Value(s.lastReviewedAt),
        ),
      );

  /// Server states win only when their last review is newer (spec §13.8).
  Future<void> mergeServer(Map<String, CardState> server) async {
    final local = await statesFor(server.keys);
    await db.transaction(() async {
      for (final MapEntry(key: id, value: s) in server.entries) {
        final mine = local[id];
        if (mine == null || (s.lastReviewedAt ?? 0) > (mine.lastReviewedAt ?? 0)) await putState(id, s);
      }
    });
  }

  Future<void> addLog(LocalReviewLog log) => db
      .into(db.srsReviewLogs)
      .insert(
        SrsReviewLogsCompanion.insert(
          id: log.id,
          flashcardId: log.flashcardId,
          rating: log.rating.name,
          before: jsonEncode(log.before.toJson()),
          after: jsonEncode(log.after.toJson()),
          reviewedAt: log.reviewedAt,
          durationMs: Value(log.durationMs),
        ),
      );

  /// Undo: the log is resent (as undone) on the next sync.
  Future<void> markUndone(String logId) => (db.update(
    db.srsReviewLogs,
  )..where((t) => t.id.equals(logId))).write(const SrsReviewLogsCompanion(undone: Value(true), synced: Value(false)));

  Future<List<LocalReviewLog>> pendingLogs({int limit = 500}) async {
    final rows =
        await (db.select(db.srsReviewLogs)
              ..where((t) => t.synced.equals(false))
              ..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)])
              ..limit(limit))
            .get();
    return [
      for (final r in rows)
        LocalReviewLog(
          id: r.id,
          flashcardId: r.flashcardId,
          rating: Rating.values.byName(r.rating),
          before: CardState.fromJson(jsonDecode(r.before) as Map<String, Object?>),
          after: CardState.fromJson(jsonDecode(r.after) as Map<String, Object?>),
          reviewedAt: r.reviewedAt,
          durationMs: r.durationMs,
          undone: r.undone,
        ),
    ];
  }

  Future<void> markSynced(Iterable<String> logIds) => (db.update(
    db.srsReviewLogs,
  )..where((t) => t.id.isIn(logIds.toList()))).write(const SrsReviewLogsCompanion(synced: Value(true)));

  /// New cards introduced and reviews done in the current business day (daily limits, §13.5).
  Future<({int newDone, int reviewsDone})> todayCounts(int now) async {
    final start = startOfBusinessDay(businessDay(now));
    final rows = await (db.select(
      db.srsReviewLogs,
    )..where((t) => t.reviewedAt.isBiggerOrEqualValue(start) & t.undone.equals(false))).get();
    var newDone = 0;
    var reviewsDone = 0;
    for (final r in rows) {
      final before = (jsonDecode(r.before) as Map<String, Object?>)['state'];
      if (before == 'new') newDone++;
      if (before == 'review') reviewsDone++;
    }
    return (newDone: newDone, reviewsDone: reviewsDone);
  }

  Future<String?> cursor() => db.getValue(cursorKey);
  Future<void> setCursor(String cursor) => db.setValue(cursorKey, cursor);
}
