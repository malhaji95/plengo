import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/flashcard_repository.dart';
import '../../core/content/study_card.dart';
import '../../core/srs/queue.dart';
import '../../core/srs/scheduler.dart';
import '../../core/srs/srs_key.dart';
import '../../core/srs/srs_store.dart';
import '../my_decks/my_decks_providers.dart';
import '../../shared/util/uuid.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>(
  (ref) => FlashcardRepository(ref.watch(apiClientProvider)),
);

final srsStoreProvider = Provider<SrsStore>((ref) => SrsStore(ref.watch(databaseProvider)));

/// The clock used for scheduling; tests replace it.
final clockProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

/// Daily limits (spec §13.4): remote defaults until the settings screen (Phase 10) stores the
/// student's own values.
final srsLimitsProvider = Provider<({int newPerDay, int maxReviews})>((ref) {
  final defaults = ref.watch(remoteConfigProvider).value?.srsDefaults;
  return (
    newPerDay: defaults?.newCardsPerDay.toInt() ?? Srs.newCardsPerDay,
    maxReviews: defaults?.maxReviewsPerDay.toInt() ?? Srs.maxReviewsPerDay,
  );
});

final decksProvider = FutureProvider.autoDispose.family<List<StudentDeck>, DeckQuery>(
  (ref, q) => ref.watch(flashcardRepositoryProvider).decks(q),
);

final deckProvider = FutureProvider.autoDispose.family<StudentDeck, String>(
  (ref, id) => ref.watch(flashcardRepositoryProvider).deck(id),
);

/// Cards with signed image URLs (valid one hour).
final deckCardsProvider = FutureProvider.autoDispose.family<DeckCards, String>(
  (ref, id) => ref.watch(flashcardRepositoryProvider).deckCards(id),
);

/// Pushes pending reviews and pulls other devices' changes. Failures (offline) are retried on the
/// next rating or session start; nothing is lost because logs stay local until acknowledged.
class SrsSync {
  SrsSync(this.ref);

  final Ref ref;
  Future<void>? _running;
  Timer? _debounce;

  Future<void> syncNow() {
    return _running ??= () async {
      try {
        // Student cards must reach the server before their reviews do.
        await ref.read(myDecksSyncProvider).syncNow();
        final repo = ref.read(flashcardRepositoryProvider);
        final store = ref.read(srsStoreProvider);
        final decks = ref.read(myDecksStoreProvider);
        Future<bool?> ready(String key) async {
          if (!SrsKey.isUserCard(key)) return true;
          final card = await decks.card(SrsKey.idOf(key));
          return card == null ? null : !card.dirty || card.deletedAt != null;
        }

        while (await repo.push(store, ready: ready) > 0) {}
        await repo.pull(store);
      } catch (_) {
        // Offline or server error: keep the logs for later.
      } finally {
        _running = null;
      }
    }();
  }

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }
}

final srsSyncProvider = Provider<SrsSync>((ref) {
  final sync = SrsSync(ref);
  ref.onDispose(() => sync._debounce?.cancel());
  return sync;
});

/// Where a study session takes its cards from: one official deck, one of the student's decks, or
/// every due card (optionally one subject).
typedef StudySource = ({String? deckId, String? myDeckId, String? subjectId});

class StudyState {
  const StudyState({
    required this.cards,
    required this.order,
    required this.states,
    required this.queue,
    required this.flipped,
    required this.undoCount,
  });

  final Map<String, StudyCard> cards;
  final List<String> order;
  final Map<String, CardState> states;
  final QueueSnapshot queue;
  final bool flipped;
  final int undoCount;

  StudyCard? get current => queue.next == null ? null : cards[queue.next];

  StudyState copyWith({Map<String, CardState>? states, QueueSnapshot? queue, bool? flipped, int? undoCount}) =>
      StudyState(
        cards: cards,
        order: order,
        states: states ?? this.states,
        queue: queue ?? this.queue,
        flipped: flipped ?? this.flipped,
        undoCount: undoCount ?? this.undoCount,
      );
}

/// A study session (spec §13.3–§13.6): the queue is rebuilt after every rating; each rating is
/// stored locally with its log and synced in the background. Up to 10 ratings can be undone.
class StudyController extends AsyncNotifier<StudyState> {
  StudyController(this.source);

  final StudySource source;
  static const maxUndo = 10;
  final _undo = <({String cardId, CardState before, String logId})>[];
  int _shownAt = 0;

  SrsStore get _store => ref.read(srsStoreProvider);
  int _now() => ref.read(clockProvider)();

  @override
  Future<StudyState> build() async {
    final repo = ref.read(flashcardRepositoryProvider);
    final List<StudyCard> cards;
    final serverStates = <String, CardState>{};
    if (source.myDeckId != null) {
      // The student's own deck works fully offline (§13.9); sync in the background.
      unawaited(ref.read(srsSyncProvider).syncNow());
      final rows = await ref.read(myDecksStoreProvider).cards(source.myDeckId!);
      cards = [
        for (final r in rows)
          if (!r.locked) StudyCard.own(r),
      ];
    } else if (source.deckId != null) {
      await ref.read(srsSyncProvider).syncNow();
      cards = [for (final c in (await repo.deckCards(source.deckId!)).cards) StudyCard.official(c)];
    } else {
      await ref.read(srsSyncProvider).syncNow();
      final due = await repo.due(subjectId: source.subjectId);
      final own = {
        for (final r in await ref.read(myDecksStoreProvider).cardsByIds(due.userCards.map((d) => d.card.id))) r.id: r,
      };
      cards = [
        for (final d in due.cards) StudyCard.official(d.card),
        for (final d in due.userCards)
          if (own[d.card.id] != null) StudyCard.own(own[d.card.id]!),
      ];
      for (final d in due.cards) {
        serverStates[d.card.id] = FlashcardRepository.cardStateOf(d.state);
      }
      for (final d in due.userCards) {
        serverStates[SrsKey.userCard(d.card.id)] = FlashcardRepository.cardStateOf(d.state);
      }
    }
    await _store.mergeServer(serverStates);
    final order = [for (final c in cards) c.key];
    final states = await _store.statesFor(order);
    _shownAt = _now();
    return StudyState(
      cards: {for (final c in cards) c.key: c},
      order: order,
      states: states,
      queue: await _queue(order, states),
      flipped: false,
      undoCount: 0,
    );
  }

  Future<QueueSnapshot> _queue(List<String> order, Map<String, CardState> states) async {
    final now = _now();
    final limits = ref.read(srsLimitsProvider);
    final done = await _store.todayCounts(now);
    return buildQueue(
      order: order,
      states: states,
      now: now,
      // The global due session reviews cards already in progress; new cards come from decks.
      newLimit: source.deckId == null && source.myDeckId == null ? 0 : limits.newPerDay - done.newDone,
      reviewLimit: limits.maxReviews - done.reviewsDone,
    );
  }

  void flip() {
    final s = state.value;
    if (s == null || s.current == null) return;
    state = AsyncData(s.copyWith(flipped: !s.flipped));
  }

  /// Predicted states and labels for the three buttons of the current card.
  Map<Rating, ({CardState state, String label})>? previews() {
    final s = state.value;
    final card = s?.current;
    if (s == null || card == null) return null;
    final now = _now();
    return preview(s.states[card.key] ?? CardState.newCard(now), now, card.key);
  }

  Future<void> rate(Rating rating) async {
    final s = state.value;
    final card = s?.current;
    if (s == null || card == null || !s.flipped) return;
    final now = _now();
    final before = s.states[card.key] ?? CardState.newCard(now);
    final after = schedule(before, rating, now, card.key);
    final logId = uuidV4();
    await _store.putState(card.key, after);
    await _store.addLog(
      LocalReviewLog(
        id: logId,
        flashcardId: card.key,
        rating: rating,
        before: before,
        after: after,
        reviewedAt: now,
        durationMs: now - _shownAt,
      ),
    );
    _undo.add((cardId: card.key, before: before, logId: logId));
    if (_undo.length > maxUndo) _undo.removeAt(0);
    final states = {...s.states, card.key: after};
    _shownAt = _now();
    state = AsyncData(
      s.copyWith(states: states, queue: await _queue(s.order, states), flipped: false, undoCount: _undo.length),
    );
    ref.read(srsSyncProvider).schedule();
  }

  /// Restores the previous state of the last rated card and shows it again (spec §13.3).
  Future<void> undo() async {
    final s = state.value;
    if (s == null || _undo.isEmpty) return;
    final last = _undo.removeLast();
    await _store.putState(last.cardId, last.before);
    await _store.markUndone(last.logId);
    final states = {...s.states, last.cardId: last.before};
    final queue = await _queue(s.order, states);
    state = AsyncData(
      s.copyWith(
        states: states,
        // Show the undone card again, whatever the queue would pick.
        queue: QueueSnapshot(
          next: last.cardId,
          newCount: queue.newCount,
          learningCount: queue.learningCount,
          reviewCount: queue.reviewCount,
          nextDueAt: null,
        ),
        flipped: false,
        undoCount: _undo.length,
      ),
    );
    ref.read(srsSyncProvider).schedule();
  }
}

final studyControllerProvider = AsyncNotifierProvider.autoDispose.family<StudyController, StudyState, StudySource>(
  StudyController.new,
);
