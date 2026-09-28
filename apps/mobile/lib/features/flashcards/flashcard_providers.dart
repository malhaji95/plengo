import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/flashcard_repository.dart';
import '../../core/srs/queue.dart';
import '../../core/srs/scheduler.dart';
import '../../core/srs/srs_store.dart';
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
        final repo = ref.read(flashcardRepositoryProvider);
        final store = ref.read(srsStoreProvider);
        while (await repo.push(store) > 0) {}
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

/// Where a study session takes its cards from: one deck, or every due card (optionally one subject).
typedef StudySource = ({String? deckId, String? subjectId});

class StudyState {
  const StudyState({
    required this.cards,
    required this.order,
    required this.states,
    required this.queue,
    required this.flipped,
    required this.undoCount,
  });

  final Map<String, StudentCard> cards;
  final List<String> order;
  final Map<String, CardState> states;
  final QueueSnapshot queue;
  final bool flipped;
  final int undoCount;

  StudentCard? get current => queue.next == null ? null : cards[queue.next];

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
    await ref.read(srsSyncProvider).syncNow();
    final List<StudentCard> cards;
    final serverStates = <String, CardState>{};
    if (source.deckId != null) {
      cards = (await repo.deckCards(source.deckId!)).cards;
    } else {
      final due = await repo.due(subjectId: source.subjectId);
      cards = [for (final d in due.cards) d.card];
      for (final d in due.cards) {
        serverStates[d.card.id] = FlashcardRepository.cardStateOf(d.state);
      }
    }
    await _store.mergeServer(serverStates);
    final order = [for (final c in cards) c.id];
    final states = await _store.statesFor(order);
    _shownAt = _now();
    return StudyState(
      cards: {for (final c in cards) c.id: c},
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
      newLimit: source.deckId == null ? 0 : limits.newPerDay - done.newDone,
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
    return preview(s.states[card.id] ?? CardState.newCard(now), now, card.id);
  }

  Future<void> rate(Rating rating) async {
    final s = state.value;
    final card = s?.current;
    if (s == null || card == null || !s.flipped) return;
    final now = _now();
    final before = s.states[card.id] ?? CardState.newCard(now);
    final after = schedule(before, rating, now, card.id);
    final logId = uuidV4();
    await _store.putState(card.id, after);
    await _store.addLog(
      LocalReviewLog(
        id: logId,
        flashcardId: card.id,
        rating: rating,
        before: before,
        after: after,
        reviewedAt: now,
        durationMs: now - _shownAt,
      ),
    );
    _undo.add((cardId: card.id, before: before, logId: logId));
    if (_undo.length > maxUndo) _undo.removeAt(0);
    final states = {...s.states, card.id: after};
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
