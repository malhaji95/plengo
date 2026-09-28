import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/learning/exam_store.dart';
import 'package:plengo/features/quizzes/quiz_providers.dart';

import 'helpers.dart';

const offline = ApiException('NETWORK_ERROR', ApiException.networkMessage);

/// Arabic-only labels: Latin runs are wrapped in bidi isolates on screen.
String ar(String id) => const {'q1': 'الأول', 'q2': 'الثاني'}[id] ?? id;

AttemptQuestion question(String id, {CheckResult? result, String? selected, bool flagged = false}) => AttemptQuestion(
  questionId: id,
  type: AttemptQuestionType.mcq,
  unitId: null,
  lessonId: null,
  questionText: 'سؤال ${ar(id)}',
  options: [
    AttemptOption(id: '$id-a', text: 'خيار أ ${ar(id)}', isCorrect: result == null ? null : true),
    AttemptOption(id: '$id-b', text: 'خيار ب ${ar(id)}', isCorrect: result == null ? null : false),
  ],
  selectedOptionId: selected,
  writtenAnswer: null,
  flagged: flagged,
  answeredAt: null,
  timeSpentMs: null,
  result: result,
);

AttemptSummary summary({
  String id = 'a1',
  AttemptSummaryMode mode = AttemptSummaryMode.exam,
  AttemptStatus status = AttemptStatus.inProgress,
  String? deadlineAt,
  int total = 2,
  int? correct,
  int? wrong,
  int? skipped,
  int? score,
}) => AttemptSummary(
  id: id,
  clientAttemptId: 'c-$id',
  quizId: 'q1',
  source: AttemptSummarySource.curated,
  mode: mode,
  titleAr: 'اختبار الحركة',
  subjectId: 'p',
  teacherTrackId: null,
  filters: null,
  status: status,
  startedAt: '2026-09-27T09:00:00.000Z',
  deadlineAt: deadlineAt,
  submittedAt: status == AttemptStatus.submitted ? '2026-09-27T09:10:00.000Z' : null,
  submittedLate: false,
  totalCount: total,
  answeredCount: 0,
  correctCount: correct,
  wrongCount: wrong,
  skippedCount: skipped,
  scorePercent: score,
  passingScorePercent: null,
  passed: null,
  timeSpentMs: status == AttemptStatus.submitted ? 600000 : null,
);

Attempt attempt({
  AttemptSummaryMode mode = AttemptSummaryMode.exam,
  String? deadlineAt,
  List<AttemptQuestion>? questions,
}) => Attempt(
  attempt: summary(mode: mode, deadlineAt: deadlineAt),
  questions: questions ?? [question('q1'), question('q2')],
  serverTime: '2026-09-27T09:00:00.000Z',
);

const correctResult = CheckResult(isCorrect: true, correctOptionId: 'q1-a', correctAnswer: null, explanation: 'لأن');
const wrongResult = CheckResult(isCorrect: false, correctOptionId: 'q2-a', correctAnswer: null, explanation: 'شرح');

Attempt graded() => Attempt(
  attempt: summary(status: AttemptStatus.submitted, correct: 1, wrong: 1, skipped: 0, score: 50),
  questions: [
    question('q1', result: correctResult, selected: 'q1-a'),
    question('q2', result: wrongResult, selected: 'q2-b', flagged: true),
  ],
  serverTime: '2026-09-27T09:10:00.000Z',
);

StudentQuiz quiz({int total = 3, int accessible = 1, bool locked = false, String? inProgress}) => StudentQuiz(
  id: 'q1',
  subjectId: 'p',
  teacherTrackId: null,
  unitId: null,
  lessonId: null,
  titleAr: 'اختبار الحركة',
  description: null,
  allowedModes: StudentQuizAllowedModes.both,
  timeLimitSeconds: 1200,
  passingScorePercent: 60,
  maxAttempts: null,
  isMockExam: false,
  allowOffline: true,
  isFree: false,
  sortOrder: 0,
  contentVersion: 1,
  totalCount: total,
  accessibleCount: accessible,
  lockedCount: total - accessible,
  locked: locked,
  attemptsUsed: 0,
  bestScorePercent: null,
  inProgressAttemptId: inProgress,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const StartAttemptRequest(
        clientAttemptId: '',
        source: StartAttemptRequestSource.curated,
        mode: StartAttemptRequestMode.practice,
      ),
    );
    registerFallbackValue(const SaveAnswerRequest());
    registerFallbackValue(const CheckAttemptAnswerRequest());
    registerFallbackValue(const SubmitAttemptRequest(answers: []));
    registerFallbackValue(BookmarkItemType.question);
    registerFallbackValue(MistakeFilterStatus.active);
  });

  Future<PumpedApp> open(
    WidgetTester tester,
    String location, {
    void Function(MockLearningRepository)? arrange,
    void Function(MockCatalogRepository)? arrangeCatalog,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await pumpApp(tester, signedInAs: testMe, arrangeLearning: arrange, arrangeCatalog: arrangeCatalog);
    app.container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('quiz detail: mixed availability, locked notice, both modes', (tester) async {
    final app = await open(
      tester,
      '/quizzes/q1',
      arrange: (l) {
        when(() => l.quiz('q1')).thenAnswer((_) async => quiz());
        when(
          () => l.attempts(quizId: 'q1', status: AttemptStatus.submitted),
        ).thenAnswer((_) async => const AttemptSummaryPage(items: [], nextCursor: null));
        when(() => l.start(any())).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
        when(() => l.attempt('a1')).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
      },
    );
    expect(find.text('1 من 3 سؤال متاح'), findsOneWidget);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);
    expect(find.text('وضع التدريب'), findsOneWidget);
    expect(find.text('وضع الامتحان'), findsOneWidget);

    await tester.tap(find.text('وضع التدريب'));
    await tester.pumpAndSettle();
    final req = verify(() => app.learning.start(captureAny())).captured.single as StartAttemptRequest;
    expect(req.source, StartAttemptRequestSource.curated);
    expect(req.mode, StartAttemptRequestMode.practice);
    expect(req.quizId, 'q1');
    expect(find.text('سؤال الأول'), findsOneWidget);
  });

  testWidgets('a quiz with nothing accessible offers no modes', (tester) async {
    await open(
      tester,
      '/quizzes/q1',
      arrange: (l) {
        when(() => l.quiz('q1')).thenAnswer((_) async => quiz(accessible: 0, locked: true));
        when(
          () => l.attempts(quizId: 'q1', status: AttemptStatus.submitted),
        ).thenAnswer((_) async => const AttemptSummaryPage(items: [], nextCursor: null));
      },
    );
    expect(find.text('وضع التدريب'), findsNothing);
    expect(find.text('وضع الامتحان'), findsNothing);
  });

  testWidgets('practice: تحقق grades on the server, then التالي, then results', (tester) async {
    final app = await open(
      tester,
      '/attempts/a1',
      arrange: (l) {
        var submitted = false;
        when(
          () => l.attempt('a1'),
        ).thenAnswer((_) async => submitted ? graded() : attempt(mode: AttemptSummaryMode.practice));
        when(() => l.check('a1', 'q1', any())).thenAnswer((_) async => correctResult);
        when(() => l.check('a1', 'q2', any())).thenAnswer((_) async => wrongResult);
        when(() => l.submit('a1', any())).thenAnswer((_) async {
          submitted = true;
          return graded();
        });
      },
    );
    expect(find.text('سؤال الأول'), findsOneWidget);
    await tester.tap(find.text('خيار أ الأول'));
    await tester.pump();
    await tester.tap(find.text('تحقق'));
    await tester.pumpAndSettle();
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.text('لأن'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خيار ب الثاني'));
    await tester.pump();
    await tester.tap(find.text('تحقق'));
    await tester.pumpAndSettle();
    expect(find.text('إجابة خاطئة'), findsOneWidget);
    final body =
        verify(() => app.learning.check('a1', 'q2', captureAny())).captured.single as CheckAttemptAnswerRequest;
    expect(body.selectedOptionId, 'q2-b');

    await tester.tap(find.text('عرض النتيجة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('score')), findsOneWidget);
    expect(find.text('أعد الأخطاء فقط'), findsOneWidget);
    // Filters (§15.6).
    await tester.tap(find.text('الخاطئة'));
    await tester.pumpAndSettle();
    expect(find.text('سؤال الثاني'), findsOneWidget);
    expect(find.text('سؤال الأول'), findsNothing);
    await tester.tap(find.text('المعلّمة'));
    await tester.pumpAndSettle();
    expect(find.text('سؤال الثاني'), findsOneWidget);
  });

  testWidgets('retry wrong only starts a mistakes attempt limited to the wrong questions', (tester) async {
    final app = await open(
      tester,
      '/attempts/a1/results',
      arrange: (l) {
        when(() => l.attempt('a1')).thenAnswer((_) async => graded());
        when(() => l.start(any())).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
      },
    );
    await tester.tap(find.text('أعد الأخطاء فقط'));
    await tester.pumpAndSettle();
    final req = verify(() => app.learning.start(captureAny())).captured.single as StartAttemptRequest;
    expect(req.source, StartAttemptRequestSource.mistakes);
    expect(req.filters?.questionIds, ['q2']);
  });

  testWidgets('exam offline mid-attempt: answers kept locally, submitted on reconnect (§37.5)', (tester) async {
    var online = false;
    final app = await open(
      tester,
      '/attempts/a1',
      arrange: (l) {
        when(() => l.attempt('a1')).thenAnswer((_) async => attempt());
        when(() => l.save('a1', any(), any())).thenAnswer((_) async => throw offline);
        when(() => l.submit('a1', any())).thenAnswer((_) async {
          if (!online) throw offline;
          return graded();
        });
      },
    );
    expect(find.text('السؤال 1 من 2 · أجبت عن 0'), findsOneWidget);
    await tester.tap(find.text('خيار أ الأول'));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد اتصال. تُحفظ إجاباتك على الجهاز وتُرسل لاحقاً.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flag')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('سؤال الثاني'), findsOneWidget);
    await tester.tap(find.text('إنهاء الامتحان'));
    await tester.pumpAndSettle();
    // Review before submitting: q2 has no answer, q1 is flagged.
    expect(find.text('بلا إجابة (1):'), findsOneWidget);
    expect(find.text('المعلّمة للمراجعة (1):'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إنهاء الامتحان').last);
    await tester.pumpAndSettle();
    expect(find.text('تم حفظ إجاباتك على الجهاز. سيُرسل الامتحان تلقائياً عند عودة الاتصال.'), findsOneWidget);

    final store = ExamStore(app.db);
    expect((await store.pendingSubmissions()).single.attempt.attempt.id, 'a1');
    expect((await store.answers('a1'))['q1']?.selectedOptionId, 'q1-a');

    // Still offline: "إرسال الآن" keeps it pending.
    await tester.tap(find.text('إرسال الآن'));
    await tester.pumpAndSettle();
    expect((await store.pendingSubmissions()), hasLength(1));

    // The connection returns: the background sync sends the stored answers.
    online = true;
    await app.container.read(examSyncProvider).syncNow();
    final body = verify(() => app.learning.submit('a1', captureAny())).captured.last as SubmitAttemptRequest;
    expect(body.answers.single.questionId, 'q1');
    expect(body.answers.single.selectedOptionId, 'q1-a');
    expect(body.answers.single.flagged, isTrue);
    expect(await store.pendingSubmissions(), isEmpty);
    expect(await store.answers('a1'), isEmpty);
  });

  testWidgets('exam: "إرسال الآن" after reconnecting shows results and clears the device copy', (tester) async {
    var online = false;
    var submitted = false;
    final app = await open(
      tester,
      '/attempts/a1',
      arrange: (l) {
        when(() => l.attempt('a1')).thenAnswer((_) async => submitted ? graded() : attempt());
        when(() => l.save('a1', any(), any())).thenAnswer((_) async => throw offline);
        when(() => l.submit('a1', any())).thenAnswer((_) async {
          if (!online) throw offline;
          submitted = true;
          return graded();
        });
      },
    );
    await tester.tap(find.text('خيار أ الأول'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنهاء الامتحان'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إنهاء الامتحان').last);
    await tester.pumpAndSettle();
    online = true;
    await tester.tap(find.text('إرسال الآن'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('score')), findsOneWidget);
    final store = ExamStore(app.db);
    expect(await store.pendingSubmissions(), isEmpty);
    expect(await store.answers('a1'), isEmpty);
  });

  testWidgets('exam: grid jumps between questions; the timer counts down from the server deadline', (tester) async {
    await open(
      tester,
      '/attempts/a1',
      arrange: (l) {
        when(() => l.attempt('a1')).thenAnswer(
          (_) async => attempt(deadlineAt: DateTime.now().toUtc().add(const Duration(minutes: 20)).toIso8601String()),
        );
        when(() => l.save('a1', any(), any())).thenAnswer(
          (_) async => const SavedAnswer(
            questionId: 'q1',
            selectedOptionId: null,
            writtenAnswer: null,
            flagged: false,
            answeredAt: null,
          ),
        );
      },
    );
    expect(find.byKey(const Key('exam-timer')), findsOneWidget);
    await tester.tap(find.byTooltip('شبكة الأسئلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.text('سؤال الثاني'), findsOneWidget);
  });

  testWidgets('mistake bank: grouped list, remove, and "اختبر أخطائي"', (tester) async {
    Mistake mistake(String id, String unit) => Mistake(
      questionId: id,
      type: MistakeType.mcq,
      questionText: 'خطأ رقم',
      subjectId: 'p',
      subjectNameAr: 'الفيزياء',
      teacherTrackId: null,
      trackTitleAr: null,
      unitId: 'u',
      unitNameAr: unit,
      lessonId: null,
      lessonNameAr: null,
      status: MistakeStatus.active,
      wrongCount: 2,
      correctStreak: 1,
      firstWrongAt: '2026-09-20T00:00:00Z',
      lastWrongAt: '2026-09-21T00:00:00Z',
    );
    final app = await open(
      tester,
      '/review/mistakes',
      arrange: (l) {
        when(() => l.mistakes(status: any(named: 'status'))).thenAnswer(
          (_) async =>
              MistakeList(items: [mistake('m1', 'الميكانيك')], activeCount: 1, masteredCount: 3, masteryStreak: 2),
        );
        when(() => l.removeMistake('m1')).thenAnswer((_) async {});
      },
    );
    expect(find.text('الفيزياء · الميكانيك'), findsOneWidget);
    expect(find.text('خطأ رقم'), findsOneWidget);
    expect(find.text('متقنة (3)'), findsOneWidget);
    expect(find.text('يُتقن السؤال بعد 2 إجابات صحيحة متتالية'), findsOneWidget);
    await tester.tap(find.byTooltip('إزالة من الأخطاء'));
    await tester.pumpAndSettle();
    verify(() => app.learning.removeMistake('m1')).called(1);
  });

  testWidgets('saved tab: locked bookmarks show as locked without content', (tester) async {
    await open(
      tester,
      '/saved',
      arrange: (l) {
        when(() => l.bookmarks()).thenAnswer(
          (_) async => const BookmarkList(
            items: [
              Bookmark(
                id: 'b1',
                itemType: BookmarkItemType.question,
                itemId: 'q9',
                createdAt: '2026-09-20T00:00:00Z',
                locked: true,
                available: true,
                titleAr: null,
                subjectId: 'p',
                subjectNameAr: 'الفيزياء',
                question: null,
                deck: null,
                card: null,
              ),
            ],
            urlsExpireAt: '',
          ),
        );
      },
    );
    expect(find.text('سؤال مقفل'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('home: continue learning resumes an unfinished exam', (tester) async {
    await open(
      tester,
      '/home',
      arrange: (l) {
        when(() => l.resume()).thenAnswer(
          (_) async => const [
            ResumeItem(
              subjectId: 'p',
              subjectNameAr: 'الفيزياء',
              teacherTrackId: null,
              trackTitleAr: null,
              unitId: null,
              unitNameAr: null,
              lessonId: null,
              lessonNameAr: null,
              activityType: ResumeItemActivityType.quiz,
              itemId: 'q1',
              itemTitleAr: 'اختبار الحركة',
              attemptId: 'a1',
              lastActivityAt: '2026-09-27T09:00:00Z',
            ),
          ],
        );
        when(() => l.attempt('a1')).thenAnswer((_) async => attempt());
      },
    );
    expect(find.text('اختبار الحركة'), findsOneWidget);
    expect(find.text('متابعة الاختبار · الفيزياء'), findsOneWidget);
    await tester.tap(find.text('اختبار الحركة'));
    await tester.pumpAndSettle();
    expect(find.text('سؤال الأول'), findsOneWidget);
  });

  testWidgets('statistics: overview tiles, trend and flashcards', (tester) async {
    const acc = Accuracy(answered: 40, correct: 30, accuracyPercent: 75);
    await open(
      tester,
      '/review/stats',
      arrange: (l) {
        when(() => l.overview()).thenAnswer(
          (_) async => const StatsOverview(
            totals: acc,
            quizzesCompleted: 3,
            studyDays: 5,
            currentStreak: 2,
            averageTimeMs: 12000,
            mistakes: Mistakes(active: 4, mastered: 1),
            subjects: [
              SubjectAccuracy(
                answered: 40,
                correct: 30,
                accuracyPercent: 75,
                subjectId: 'p',
                subjectNameAr: 'الفيزياء',
                teacherTrackId: null,
                trackTitleAr: null,
              ),
            ],
            byType: [],
            weakestUnits: [],
            mostMissed: [],
          ),
        );
        when(() => l.trend()).thenAnswer(
          (_) async => StatsTrend(
            weeks: [
              for (var i = 0; i < 12; i++)
                const TrendWeek(answered: 4, correct: 3, accuracyPercent: 75, weekStart: '2026-07-01'),
            ],
          ),
        );
        when(() => l.flashcardStats()).thenAnswer(
          (_) async => FlashcardStats(
            dueToday: 7,
            forecast: [for (var i = 0; i < 7; i++) const DayCount(date: '2026-09-27', count: 2)],
            reviewsPerDay: [for (var i = 0; i < 30; i++) const DayCount(date: '2026-09-01', count: 1)],
            retentionPercent: 90,
            byState: const ByState(newValue: 1, learning: 2, review: 3, relearning: 0),
          ),
        );
      },
    );
    expect(find.text('أسئلة مُجابة'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('2 يوم'), findsOneWidget);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.text('مستحقة اليوم'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('random practice sends the chosen filters', (tester) async {
    final app = await open(
      tester,
      '/practice/random?subjectId=p',
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => SubjectOutline(
          subject: subject('p', 'الفيزياء'),
          units: const [],
          lessons: const [],
          tracks: const [],
          access: noAccess,
          questionCount: const ContentCount(total: 3, free: 1),
          deckCount: noQuestions,
          quizCount: noQuestions,
        ),
      ),
      arrange: (l) {
        when(() => l.start(any())).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
        when(() => l.attempt('a1')).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
      },
    );
    await tester.tap(find.text('إجابة مكتوبة'));
    await tester.tap(find.text('امتحان'));
    await tester.pump();
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    final req = verify(() => app.learning.start(captureAny())).captured.single as StartAttemptRequest;
    expect(req.source, StartAttemptRequestSource.random);
    expect(req.mode, StartAttemptRequestMode.exam);
    expect(req.filters?.subjectId, 'p');
    expect(req.filters?.types, [AttemptFiltersTypes.written]);
    expect(req.filters?.count, 20);
  });
}
