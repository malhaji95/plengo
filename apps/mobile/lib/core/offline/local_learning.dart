import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../db/app_database.dart';
import '../learning/learning_repository.dart';
import 'offline_content.dart';

const localAttemptPrefix = 'local-';
bool isLocalAttempt(String id) => id.startsWith(localAttemptPrefix);

/// Attempts taken from downloaded packs (spec §22.6), kept in the local database until the server
/// has them.
class LocalAttemptStore {
  LocalAttemptStore(this.db);

  final AppDatabase db;

  Future<LocalAttemptRow?> row(String id) =>
      (db.select(db.localAttempts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Attempt?> get(String id) async {
    final r = await row(id);
    return r == null ? null : Attempt.fromJson(jsonDecode(r.attempt) as Map<String, Object?>);
  }

  Future<void> put(Attempt a, {required int createdAt, OfflineAttempt? payload}) async {
    final existing = await row(a.attempt.id);
    await db
        .into(db.localAttempts)
        .insert(
          LocalAttemptsCompanion.insert(
            id: a.attempt.id,
            attempt: jsonEncode(a),
            payload: Value(payload == null ? existing?.payload : jsonEncode(payload)),
            submitted: Value(a.attempt.status == AttemptStatus.submitted),
            synced: Value(existing?.synced ?? false),
            serverAttemptId: Value(existing?.serverAttemptId),
            createdAt: existing?.createdAt ?? createdAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<LocalAttemptRow>> pending() =>
      (db.select(db.localAttempts)..where((t) => t.submitted.equals(true) & t.synced.equals(false))).get();

  Future<List<Attempt>> submitted() async => [
    for (final r in await (db.select(db.localAttempts)..where((t) => t.submitted.equals(true))).get())
      Attempt.fromJson(jsonDecode(r.attempt) as Map<String, Object?>),
  ];

  Future<void> markSynced(String id, String? serverAttemptId) =>
      (db.update(db.localAttempts)..where((t) => t.id.equals(id))).write(
        LocalAttemptsCompanion(synced: const Value(true), serverAttemptId: Value(serverAttemptId)),
      );

  // ---- mistakes mirror ----

  Future<void> recordWrong(String questionId, int at) => db
      .into(db.localMistakes)
      .insertOnConflictUpdate(LocalMistakesCompanion.insert(questionId: questionId, wrongAt: at));

  Future<void> clearMistakes(Iterable<String> questionIds) {
    final ids = questionIds.toList();
    return ids.isEmpty ? Future.value() : (db.delete(db.localMistakes)..where((t) => t.questionId.isIn(ids))).go();
  }

  Future<List<String>> mistakeIds() async => [for (final r in await db.select(db.localMistakes).get()) r.questionId];
}

/// The attempts API with offline packs behind it (spec §22.6): quizzes held in downloaded packs run
/// on the device (instant grading online or offline); random practice and "اختبر أخطائي" are
/// built from pack questions when the server cannot be reached. Everything else goes to the server.
class OfflineLearningRepository extends LearningRepository {
  OfflineLearningRepository(
    super.client, {
    required this.content,
    required this.local,
    required this.clock,
    this.onSubmitted,
    Random? random,
  }) : _random = random ?? Random();

  final OfflineContent content;
  final LocalAttemptStore local;
  final int Function() clock;

  /// Called after a local attempt is submitted (starts the upload).
  final void Function()? onSubmitted;
  final Random _random;

  String _iso(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  @override
  Future<Attempt> start(StartAttemptRequest body) async {
    if (body.source == StartAttemptRequestSource.curated && body.quizId != null) {
      final quiz = await content.quiz(body.quizId!);
      final questions = quiz == null ? null : await _gradable(quiz.questionIds);
      if (quiz != null && questions != null && _allows(quiz, body.mode)) {
        return _begin(
          body,
          questions: quiz.shuffleQuestions ? (questions.toList()..shuffle(_random)) : questions,
          shuffleOptions: quiz.shuffleOptions,
          quiz: quiz,
        );
      }
    }
    try {
      return await super.start(body);
    } on ApiException catch (e) {
      if (e.code != 'NETWORK_ERROR' || body.source == StartAttemptRequestSource.curated) rethrow;
      final f = body.filters;
      List<PackQuestion> pool;
      if (body.source == StartAttemptRequestSource.random) {
        if (f?.subjectId == null) rethrow;
        pool = await content.questions(
          subjectId: f!.subjectId!,
          teacherTrackId: f.teacherTrackId,
          unitId: f.unitId,
          lessonId: f.lessonId,
          types: f.types?.map((t) => OfflineQuestionType.values.firstWhere((x) => x.json == t.json)).toSet(),
        );
      } else {
        pool = [
          for (final id in await local.mistakeIds()) ?await content.question(id),
        ].where((q) => f?.subjectId == null || q.question.subjectId == f!.subjectId).toList();
      }
      pool = pool.where((q) => q.canGradeLocally).toList()..shuffle(_random);
      if (pool.isEmpty) {
        throw const ApiException('NETWORK_ERROR', 'لا توجد أسئلة محمّلة لهذا الاختيار، اتصل بالإنترنت');
      }
      return _begin(body, questions: pool.take(f?.count?.toInt() ?? 20).toList(), shuffleOptions: true);
    }
  }

  bool _allows(OfflineQuiz quiz, StartAttemptRequestMode mode) =>
      quiz.allowedModes == OfflineQuizAllowedModes.both || quiz.allowedModes.json == mode.json;

  /// Every question from packs and gradable here, or null.
  Future<List<PackQuestion>?> _gradable(List<String> ids) async {
    final out = <PackQuestion>[];
    for (final id in ids) {
      final q = await content.question(id);
      if (q == null || !q.canGradeLocally) return null;
      out.add(q);
    }
    return out.isEmpty ? null : out;
  }

  Future<Attempt> _begin(
    StartAttemptRequest body, {
    required List<PackQuestion> questions,
    required bool shuffleOptions,
    OfflineQuiz? quiz,
  }) async {
    final now = clock();
    final exam = body.mode == StartAttemptRequestMode.exam;
    final attempt = Attempt(
      attempt: AttemptSummary(
        id: '$localAttemptPrefix${body.clientAttemptId}',
        clientAttemptId: body.clientAttemptId,
        quizId: quiz?.id,
        source: AttemptSummarySource.values.firstWhere((s) => s.json == body.source.json),
        mode: exam ? AttemptSummaryMode.exam : AttemptSummaryMode.practice,
        titleAr: quiz?.titleAr ?? (body.source == StartAttemptRequestSource.random ? 'تدريب عشوائي' : 'مراجعة الأخطاء'),
        subjectId: quiz?.subjectId ?? body.filters?.subjectId,
        teacherTrackId: quiz?.teacherTrackId ?? body.filters?.teacherTrackId,
        filters: body.filters,
        status: AttemptStatus.inProgress,
        startedAt: _iso(now),
        deadlineAt: exam && quiz?.timeLimitSeconds != null ? _iso(now + quiz!.timeLimitSeconds! * 1000) : null,
        submittedAt: null,
        submittedLate: false,
        totalCount: questions.length,
        answeredCount: 0,
        correctCount: null,
        wrongCount: null,
        skippedCount: null,
        scorePercent: null,
        passingScorePercent: quiz?.passingScore,
        passed: null,
        timeSpentMs: null,
      ),
      questions: [
        for (final pq in questions)
          AttemptQuestion(
            questionId: pq.question.id,
            type: AttemptQuestionType.values.firstWhere((t) => t.json == pq.question.type.json),
            unitId: pq.question.unitId,
            lessonId: pq.question.lessonId,
            questionText: pq.question.questionText,
            options: [
              for (final o
                  in shuffleOptions && pq.question.type == OfflineQuestionType.mcq
                      ? (pq.question.options.toList()..shuffle(_random))
                      : pq.question.options)
                AttemptOption(id: o.id, text: o.text, isCorrect: null),
            ],
            selectedOptionId: null,
            writtenAnswer: null,
            flagged: false,
            answeredAt: null,
            timeSpentMs: null,
            result: null,
          ),
      ],
      serverTime: _iso(now),
    );
    await local.put(attempt, createdAt: now);
    return attempt;
  }

  Future<Attempt> _local(String id) async =>
      await local.get(id) ?? (throw const ApiException('NOT_FOUND', 'العنصر غير موجود'));

  Attempt _with(Attempt a, {AttemptSummary? summary, List<AttemptQuestion>? questions}) =>
      Attempt(attempt: summary ?? a.attempt, questions: questions ?? a.questions, serverTime: _iso(clock()));

  AttemptQuestion _answer(
    AttemptQuestion q, {
    String? selectedOptionId,
    String? writtenAnswer,
    bool? flagged,
    int? timeSpentMs,
    CheckResult? result,
  }) {
    final answered = selectedOptionId != null || writtenAnswer != null;
    return AttemptQuestion(
      questionId: q.questionId,
      type: q.type,
      unitId: q.unitId,
      lessonId: q.lessonId,
      questionText: q.questionText,
      options: result == null
          ? q.options
          : [
              for (final o in q.options)
                AttemptOption(id: o.id, text: o.text, isCorrect: o.id == result.correctOptionId),
            ],
      selectedOptionId: answered ? selectedOptionId : q.selectedOptionId,
      writtenAnswer: answered ? writtenAnswer : q.writtenAnswer,
      flagged: flagged ?? q.flagged,
      answeredAt: answered ? _iso(clock()) : q.answeredAt,
      timeSpentMs: timeSpentMs ?? q.timeSpentMs,
      result: result ?? q.result,
    );
  }

  Future<CheckResult> _grade(String questionId, {String? selectedOptionId, String? writtenAnswer}) async {
    final pq = await content.question(questionId);
    if (pq == null) throw const ApiException('CONTENT_LOCKED', 'هذا المحتوى غير متاح على حسابك');
    final result = gradeLocally(pq.question, selectedOptionId: selectedOptionId, writtenAnswer: writtenAnswer);
    if (!result.isCorrect) await local.recordWrong(questionId, clock());
    return result;
  }

  @override
  Future<Attempt> attempt(String id) => isLocalAttempt(id) ? _local(id) : super.attempt(id);

  @override
  Future<SavedAnswer> save(String attemptId, String questionId, SaveAnswerRequest body) async {
    if (!isLocalAttempt(attemptId)) return super.save(attemptId, questionId, body);
    final a = await _local(attemptId);
    if (a.attempt.status == AttemptStatus.submitted) {
      throw const ApiException('ATTEMPT_ALREADY_SUBMITTED', 'تم تسليم هذا الاختبار مسبقاً');
    }
    final questions = [
      for (final q in a.questions)
        q.questionId == questionId
            ? _answer(
                q,
                selectedOptionId: body.selectedOptionId,
                writtenAnswer: body.writtenAnswer,
                flagged: body.flagged,
                timeSpentMs: body.timeSpentMs,
              )
            : q,
    ];
    await local.put(_with(a, questions: questions), createdAt: clock());
    final q = questions.firstWhere((x) => x.questionId == questionId);
    return SavedAnswer(
      questionId: questionId,
      selectedOptionId: q.selectedOptionId,
      writtenAnswer: q.writtenAnswer,
      flagged: q.flagged,
      answeredAt: q.answeredAt,
    );
  }

  @override
  Future<CheckResult> check(String attemptId, String questionId, CheckAttemptAnswerRequest body) async {
    if (!isLocalAttempt(attemptId)) {
      // A question held in a pack is graded here, instantly (§22.6); the server re-grades on submit.
      return super.check(attemptId, questionId, body);
    }
    final a = await _local(attemptId);
    final result = await _grade(questionId, selectedOptionId: body.selectedOptionId, writtenAnswer: body.writtenAnswer);
    await local.put(
      _with(
        a,
        questions: [
          for (final q in a.questions)
            q.questionId == questionId
                ? _answer(
                    q,
                    selectedOptionId: body.selectedOptionId,
                    writtenAnswer: body.writtenAnswer,
                    timeSpentMs: body.timeSpentMs,
                    result: result,
                  )
                : q,
        ],
      ),
      createdAt: clock(),
    );
    return result;
  }

  @override
  Future<Attempt> submit(String attemptId, SubmitAttemptRequest body) async {
    if (!isLocalAttempt(attemptId)) return super.submit(attemptId, body);
    final a = await _local(attemptId);
    if (a.attempt.status == AttemptStatus.submitted) return a;
    final incoming = {for (final x in body.answers) x.questionId: x};
    final questions = <AttemptQuestion>[];
    for (final q in a.questions) {
      final given = incoming[q.questionId];
      var next = given == null
          ? q
          : _answer(
              q,
              selectedOptionId: given.selectedOptionId,
              writtenAnswer: given.writtenAnswer,
              flagged: given.flagged,
              timeSpentMs: given.timeSpentMs,
            );
      final answered = next.selectedOptionId != null || next.writtenAnswer != null;
      // Practice answers already checked keep their grade; everything else is graded now.
      if (answered && next.result == null) {
        final result = await _grade(
          q.questionId,
          selectedOptionId: next.selectedOptionId,
          writtenAnswer: next.writtenAnswer,
        );
        next = _answer(next, result: result);
      }
      questions.add(next);
    }
    final now = clock();
    final answered = questions.where((q) => q.result != null).toList();
    final correct = answered.where((q) => q.result!.isCorrect).length;
    final total = questions.length;
    final score = total == 0 ? 0 : (correct * 100 / total).round();
    final s = a.attempt;
    final summary = AttemptSummary(
      id: s.id,
      clientAttemptId: s.clientAttemptId,
      quizId: s.quizId,
      source: s.source,
      mode: s.mode,
      titleAr: s.titleAr,
      subjectId: s.subjectId,
      teacherTrackId: s.teacherTrackId,
      filters: s.filters,
      status: AttemptStatus.submitted,
      startedAt: s.startedAt,
      deadlineAt: s.deadlineAt,
      submittedAt: _iso(now),
      submittedLate: false,
      totalCount: total,
      answeredCount: answered.length,
      correctCount: correct,
      wrongCount: answered.length - correct,
      skippedCount: total - answered.length,
      scorePercent: score,
      passingScorePercent: s.passingScorePercent,
      passed: s.passingScorePercent == null ? null : score >= s.passingScorePercent!,
      timeSpentMs: body.timeSpentMs ?? now - DateTime.parse(s.startedAt).millisecondsSinceEpoch,
    );
    final done = _with(a, summary: summary, questions: questions);
    final payload = OfflineAttempt(
      clientAttemptId: s.clientAttemptId,
      source: OfflineAttemptSource.values.firstWhere((x) => x.json == s.source.json),
      mode: OfflineAttemptMode.values.firstWhere((x) => x.json == s.mode.json),
      quizId: s.quizId,
      subjectId: s.subjectId,
      teacherTrackId: s.teacherTrackId,
      questionIds: [for (final q in questions) q.questionId],
      startedAt: DateTime.parse(s.startedAt),
      submittedAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      timeSpentMs: summary.timeSpentMs,
      answers: [
        for (final q in questions)
          if (q.selectedOptionId != null || q.writtenAnswer != null || q.flagged)
            OfflineAnswer(
              questionId: q.questionId,
              selectedOptionId: q.selectedOptionId,
              writtenAnswer: q.writtenAnswer,
              flagged: q.flagged,
              timeSpentMs: q.timeSpentMs,
              localIsCorrect: q.result?.isCorrect,
            ),
      ],
    );
    await local.put(done, createdAt: now, payload: payload);
    onSubmitted?.call();
    return done;
  }

  @override
  Future<AttemptSummaryPage> attempts({String? quizId, AttemptStatus? status}) async {
    final mine = [
      for (final a in await local.submitted())
        if ((quizId == null || a.attempt.quizId == quizId) && (status == null || a.attempt.status == status)) a.attempt,
    ];
    try {
      final server = await super.attempts(quizId: quizId, status: status);
      // Offline attempts not uploaded yet still show in the history.
      final known = {for (final s in server.items) s.clientAttemptId};
      return AttemptSummaryPage(
        items: [...mine.where((m) => !known.contains(m.clientAttemptId)), ...server.items],
        nextCursor: server.nextCursor,
      );
    } on ApiException catch (e) {
      if (e.code != 'NETWORK_ERROR') rethrow;
      return AttemptSummaryPage(items: mine, nextCursor: null);
    }
  }
}

/// Uploads offline attempts (§22.6): idempotent by client id; the server re-grades and its result
/// becomes authoritative, so the local mistakes mirror of those questions is dropped afterwards.
class OfflineAttemptSync {
  OfflineAttemptSync({required this.client, required this.local});

  final ApiClient client;
  final LocalAttemptStore local;

  Future<int> push() => guardApi(() async {
    var sent = 0;
    while (true) {
      final rows = (await local.pending()).take(20).toList();
      if (rows.isEmpty) return sent;
      final attempts = [for (final r in rows) OfflineAttempt.fromJson(jsonDecode(r.payload!) as Map<String, Object?>)];
      final result = (await client.api.offline.syncOffline(body: OfflineSyncRequest(attempts: attempts))).data;
      for (final outcome in result.results) {
        final row = rows.firstWhere((r) => r.id == '$localAttemptPrefix${outcome.clientAttemptId}');
        await local.markSynced(row.id, outcome.attemptId);
        final a = attempts.firstWhere((x) => x.clientAttemptId == outcome.clientAttemptId);
        if (outcome.status == OfflineSyncOutcomeStatus.accepted) await local.clearMistakes(a.questionIds);
      }
      sent += rows.length;
    }
  });
}
