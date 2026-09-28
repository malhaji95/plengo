import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/learning/exam_store.dart';
import '../../core/learning/learning_repository.dart';
import '../../core/offline/local_learning.dart';
import '../offline/offline_providers.dart';
import '../../shared/util/uuid.dart';
import '../flashcards/flashcard_providers.dart';

/// Attempts from downloaded packs run on the device (spec §22.6); the rest go to the server.
final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => OfflineLearningRepository(
    ref.watch(apiClientProvider),
    content: ref.watch(offlineContentProvider),
    local: ref.watch(localAttemptStoreProvider),
    clock: ref.watch(clockProvider),
    onSubmitted: () => unawaited(ref.read(offlineControllerProvider.notifier).syncOnline()),
  ),
);

final examStoreProvider = Provider<ExamStore>((ref) => ExamStore(ref.watch(databaseProvider)));

final quizzesProvider = FutureProvider.autoDispose.family<List<StudentQuiz>, QuizQuery>(
  (ref, q) => ref.watch(learningRepositoryProvider).quizzes(q),
);

final quizProvider = FutureProvider.autoDispose.family<StudentQuiz, String>(
  (ref, id) => ref.watch(learningRepositoryProvider).quiz(id),
);

/// Finished attempts of one quiz, newest first.
final quizHistoryProvider = FutureProvider.autoDispose.family<List<AttemptSummary>, String>(
  (ref, quizId) async =>
      (await ref.watch(learningRepositoryProvider).attempts(quizId: quizId, status: AttemptStatus.submitted)).items,
);

final attemptProvider = FutureProvider.autoDispose.family<Attempt, String>(
  (ref, id) => ref.watch(learningRepositoryProvider).attempt(id),
);

/// Starts an attempt with a fresh idempotency key (a retried request returns the same attempt).
Future<Attempt> startAttempt(
  LearningRepository repo, {
  required StartAttemptRequestSource source,
  required StartAttemptRequestMode mode,
  String? quizId,
  AttemptFilters? filters,
}) => repo.start(
  StartAttemptRequest(clientAttemptId: uuidV4(), source: source, mode: mode, quizId: quizId, filters: filters),
);

bool isOffline(Object e) => e is ApiException && e.code == 'NETWORK_ERROR';

// ---- exam ----

class ExamState {
  const ExamState({
    required this.attempt,
    required this.answers,
    required this.index,
    required this.offline,
    required this.submitPending,
    required this.clockOffsetMs,
  });

  final Attempt attempt;
  final Map<String, LocalAnswer> answers;
  final int index;

  /// The last save could not reach the server; answers are kept on the device.
  final bool offline;

  /// Submitted while offline: sent when the connection returns (spec §15.2).
  final bool submitPending;

  /// Server time minus device time when the attempt was loaded, for the timer.
  final int clockOffsetMs;

  List<AttemptQuestion> get questions => attempt.questions;
  AttemptQuestion get current => questions[index];
  LocalAnswer answerOf(String questionId) => answers[questionId] ?? LocalAnswer(questionId: questionId, dirty: false);
  int get answeredCount => questions.where((q) => answerOf(q.questionId).answered).length;
  int get flaggedCount => questions.where((q) => answerOf(q.questionId).flagged).length;

  ExamState copyWith({Map<String, LocalAnswer>? answers, int? index, bool? offline, bool? submitPending}) => ExamState(
    attempt: attempt,
    answers: answers ?? this.answers,
    index: index ?? this.index,
    offline: offline ?? this.offline,
    submitPending: submitPending ?? this.submitPending,
    clockOffsetMs: clockOffsetMs,
  );
}

/// An exam (spec §15.2): answers change freely until submission, are saved on the device first and
/// then to the server; the exam continues through connection drops and is submitted when possible.
class ExamController extends AsyncNotifier<ExamState> {
  ExamController(this.attemptId);

  final String attemptId;
  final _debounce = <String, Timer>{};
  int _shownAt = 0;

  ExamStore get _store => ref.read(examStoreProvider);
  LearningRepository get _repo => ref.read(learningRepositoryProvider);
  int _now() => ref.read(clockProvider)();

  @override
  Future<ExamState> build() async {
    ref.onDispose(() {
      for (final t in _debounce.values) {
        t.cancel();
      }
    });
    Attempt? attempt;
    var offline = false;
    try {
      attempt = await _repo.attempt(attemptId);
      await _store.saveAttempt(attempt);
    } catch (e) {
      if (!isOffline(e)) rethrow;
      offline = true;
      attempt = (await _store.draft(attemptId))?.attempt;
      if (attempt == null) rethrow;
    }
    final draft = await _store.draft(attemptId);
    final local = await _store.answers(attemptId);
    // Server answers fill in what the device does not have (another device, or a reinstall).
    final answers = <String, LocalAnswer>{
      for (final q in attempt.questions)
        if (q.selectedOptionId != null || q.writtenAnswer != null || q.flagged)
          q.questionId: LocalAnswer(
            questionId: q.questionId,
            selectedOptionId: q.selectedOptionId,
            writtenAnswer: q.writtenAnswer,
            flagged: q.flagged,
            timeSpentMs: q.timeSpentMs,
            dirty: false,
          ),
      ...local,
    };
    final first = attempt.questions.indexWhere((q) => !(answers[q.questionId]?.answered ?? false));
    _shownAt = _now();
    final state = ExamState(
      attempt: attempt,
      answers: answers,
      index: first < 0 ? 0 : first,
      offline: offline,
      submitPending: draft?.submitPending ?? false,
      clockOffsetMs: DateTime.parse(attempt.serverTime).millisecondsSinceEpoch - _now(),
    );
    if (!offline) unawaited(_flush(state));
    return state;
  }

  /// Milliseconds left before the server deadline, or null for untimed exams.
  int? remainingMs(ExamState s) {
    final deadline = s.attempt.attempt.deadlineAt;
    if (deadline == null) return null;
    return DateTime.parse(deadline).millisecondsSinceEpoch - (_now() + s.clockOffsetMs);
  }

  Future<void> _put(LocalAnswer a, {bool immediate = false}) async {
    final s = state.requireValue;
    await _store.putAnswer(attemptId, a);
    state = AsyncData(s.copyWith(answers: {...s.answers, a.questionId: a}));
    _debounce[a.questionId]?.cancel();
    if (immediate) {
      await _send(a);
    } else {
      _debounce[a.questionId] = Timer(const Duration(milliseconds: 800), () => _send(a));
    }
  }

  Future<void> _send(LocalAnswer a) async {
    try {
      await _repo.save(
        attemptId,
        a.questionId,
        SaveAnswerRequest(
          selectedOptionId: a.selectedOptionId,
          writtenAnswer: a.writtenAnswer,
          flagged: a.flagged,
          timeSpentMs: a.timeSpentMs,
        ),
      );
      await _store.markClean(attemptId, a);
      final s = state.value;
      if (s != null && s.offline) state = AsyncData(s.copyWith(offline: false));
    } catch (e) {
      final s = state.value;
      if (s != null && isOffline(e)) state = AsyncData(s.copyWith(offline: true));
    }
  }

  /// Sends every answer the server has not acknowledged yet.
  Future<void> _flush(ExamState s) async {
    for (final a in s.answers.values.where((a) => a.dirty)) {
      await _send(a);
      if (state.value?.offline ?? true) return;
    }
  }

  Future<void> retry() async {
    final s = state.value;
    if (s != null) await _flush(s.copyWith(offline: false));
  }

  Future<void> select(String questionId, String optionId) =>
      _put(state.requireValue.answerOf(questionId).copyWith(selectedOptionId: optionId, dirty: true), immediate: true);

  Future<void> write(String questionId, String text) =>
      _put(state.requireValue.answerOf(questionId).copyWith(writtenAnswer: text, dirty: true));

  Future<void> toggleFlag(String questionId) {
    final a = state.requireValue.answerOf(questionId);
    return _put(a.copyWith(flagged: !a.flagged, dirty: true), immediate: true);
  }

  /// Moves to another question, adding the time spent on the current one.
  void goTo(int index) {
    final s = state.requireValue;
    final now = _now();
    final a = s.answerOf(s.current.questionId);
    final spent = (a.timeSpentMs ?? 0) + (now - _shownAt);
    _shownAt = now;
    final updated = a.copyWith(timeSpentMs: spent);
    unawaited(_store.putAnswer(attemptId, updated));
    state = AsyncData(s.copyWith(answers: {...s.answers, a.questionId: updated}, index: index));
  }

  /// Submits every answer in one batch. Returns the graded attempt, or null when it was kept to
  /// send later (offline). Repeating a submission is safe: the server answers with the same result.
  Future<Attempt?> submit() async {
    goTo(state.requireValue.index);
    final s = state.requireValue;
    for (final t in _debounce.values) {
      t.cancel();
    }
    final elapsed = s.attempt.attempt.startedAt.isEmpty
        ? null
        : _now() + s.clockOffsetMs - DateTime.parse(s.attempt.attempt.startedAt).millisecondsSinceEpoch;
    await _store.saveAttempt(s.attempt, submitPending: true, timeSpentMs: elapsed);
    state = AsyncData(s.copyWith(submitPending: true));
    try {
      final result = await ref.read(examSyncProvider).submitOne(attemptId);
      return result;
    } catch (e) {
      if (isOffline(e)) {
        state = AsyncData(state.requireValue.copyWith(offline: true));
        return null;
      }
      rethrow;
    }
  }
}

final examControllerProvider = AsyncNotifierProvider.autoDispose.family<ExamController, ExamState, String>(
  ExamController.new,
);

/// Sends exams submitted while offline once the connection returns (spec §15.2, §37.5).
class ExamSync {
  ExamSync(this.ref);

  final Ref ref;
  Future<void>? _running;

  /// Submits one stored exam; the local copy is removed once the server has it.
  Future<Attempt> submitOne(String attemptId) async {
    final store = ref.read(examStoreProvider);
    final draft = await store.draft(attemptId);
    final answers = await store.answers(attemptId);
    try {
      final result = await ref
          .read(learningRepositoryProvider)
          .submit(
            attemptId,
            SubmitAttemptRequest(
              answers: [
                for (final a in answers.values)
                  if (a.answered || a.flagged) a.toSubmit(),
              ],
              timeSpentMs: draft?.timeSpentMs,
            ),
          );
      await store.remove(attemptId);
      return result;
    } on ApiException catch (e) {
      // Already graded elsewhere, or gone: the local copy has nothing left to send.
      if (e.code == 'ATTEMPT_ALREADY_SUBMITTED' || e.code == 'NOT_FOUND') await store.remove(attemptId);
      rethrow;
    }
  }

  Future<void> syncNow() {
    return _running ??= () async {
      try {
        for (final d in await ref.read(examStoreProvider).pendingSubmissions()) {
          try {
            await submitOne(d.attempt.attempt.id);
          } catch (e) {
            if (isOffline(e)) return;
          }
        }
      } finally {
        _running = null;
      }
    }();
  }
}

final examSyncProvider = Provider<ExamSync>(ExamSync.new);
