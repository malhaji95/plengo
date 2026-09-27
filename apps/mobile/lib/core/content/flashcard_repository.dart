import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../srs/scheduler.dart';
import '../srs/srs_store.dart';

/// Which decks to list: a subject's general content, or one track, optionally one unit/lesson.
typedef DeckQuery = ({String subjectId, String? teacherTrackId, String? unitId, String? lessonId});

/// Official decks and cards, and SRS sync with the server (spec §13).
class FlashcardRepository {
  FlashcardRepository(this.client);

  final ApiClient client;

  Future<List<StudentDeck>> decks(DeckQuery q) => guardApi(
    () async => (await client.api.flashcards.listDecks(
      subjectId: q.subjectId,
      teacherTrackId: q.teacherTrackId,
      unitId: q.unitId,
      lessonId: q.lessonId,
    )).data,
  );

  Future<StudentDeck> deck(String id) => guardApi(() async => (await client.api.flashcards.getDeck(id: id)).data);

  Future<DeckCards> deckCards(String id) =>
      guardApi(() async => (await client.api.flashcards.getDeckCards(id: id)).data);

  Future<DueCards> due({String? subjectId}) =>
      guardApi(() async => (await client.api.srs.listDueCards(subjectId: subjectId)).data);

  static Map<String, CardState> _states(Iterable<SrsCardState> items) => {
    for (final s in items) s.flashcardId: CardState.fromJson(s.toJson()),
  };

  /// Pull states changed on other devices since the stored cursor.
  Future<void> pull(SrsStore store) => guardApi(() async {
    const limit = 500;
    while (true) {
      final page = (await client.api.srs.listSrsStates(since: await store.cursor(), limit: limit)).data;
      await store.mergeServer(_states(page.items));
      if (page.nextCursor != null) await store.setCursor(page.nextCursor!);
      if (page.items.length < limit) return;
    }
  });

  /// Push pending logs with the current states of their cards; adopt what the server now holds.
  Future<int> push(SrsStore store) => guardApi(() async {
    final logs = await store.pendingLogs();
    if (logs.isEmpty) return 0;
    final ids = {for (final l in logs) l.flashcardId};
    final states = await store.statesFor(ids);
    final result = (await client.api.srs.syncSrs(
      body: SrsSyncRequest(
        logs: [
          for (final l in logs)
            ReviewLog(
              id: l.id,
              flashcardId: l.flashcardId,
              rating: ReviewLogRating.values.byName(l.rating.name),
              stateBefore: SrsState.fromJson(l.before.toJson()),
              stateAfter: SrsState.fromJson(l.after.toJson()),
              reviewedAt: DateTime.fromMillisecondsSinceEpoch(l.reviewedAt, isUtc: true),
              durationMs: l.durationMs,
              undone: l.undone ? true : null,
            ),
        ],
        states: [
          for (final MapEntry(key: id, value: s) in states.entries)
            if (s.lastReviewedAt != null) SrsSyncState.fromJson({...s.toJson(), 'flashcardId': id}),
        ],
      ),
    )).data;
    await store.markSynced(logs.map((l) => l.id));
    await store.mergeServer(_states(result.states));
    return logs.length;
  });
}
