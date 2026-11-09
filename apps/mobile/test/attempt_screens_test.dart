import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/learning/exam_store.dart';
import 'package:plengo/features/home/streak_screen.dart';
import 'package:plengo/features/questions/questions_screen.dart';
import 'package:plengo/features/quizzes/exam_screen.dart';
import 'package:plengo/features/quizzes/practice_attempt_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';
import 'learning_test.dart' show attempt, correctResult, graded, question, summary;

/// Redesign v2 (V-Question, V-Exam, V-Results): exit sheets, the in-session streak chip, exam grid
/// states, results filters and the «متابعة» flow.
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
  });

  const saved = SavedAnswer(
    questionId: 'q',
    selectedOptionId: null,
    writtenAnswer: null,
    flagged: false,
    answeredAt: null,
  );

  Future<PumpedApp> open(
    WidgetTester tester, {
    void Function(MockLearningRepository)? arrange,
    void Function(MockCatalogRepository)? arrangeCatalog,
    void Function(MockQuestionRepository)? arrangeQuestions,
    void Function(MockHomeRepository)? arrangeHome,
    Size size = const Size(800, 1400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    return pumpApp(
      tester,
      signedInAs: testMe,
      arrangeLearning: arrange,
      arrangeCatalog: arrangeCatalog,
      arrangeQuestions: arrangeQuestions,
      arrangeHome: arrangeHome,
    );
  }

  Future<void> push(PumpedApp app, WidgetTester tester, String location) async {
    app.container.read(routerProvider).go(Routes.home);
    await tester.pumpAndSettle();
    unawaitedPush(app, location);
    await tester.pumpAndSettle();
  }

  StudentQuestion mcq(String id) => StudentQuestion(
    id: id,
    type: StudentQuestionType.mcq,
    subjectId: 'p',
    teacherTrackId: null,
    unitId: null,
    lessonId: null,
    sortOrder: 0,
    difficulty: null,
    isFree: true,
    locked: false,
    questionText: 'سؤال البنك $id',
    options: [
      StudentOption(id: '$id-a', text: 'صواب $id'),
      StudentOption(id: '$id-b', text: 'خطأ $id'),
    ],
  );

  SubjectOutline outline() => SubjectOutline(
    subject: subject('p', 'الفيزياء'),
    units: const [],
    lessons: const [],
    tracks: const [],
    access: noAccess,
    questionCount: const ContentCount(total: 4, free: 4),
    deckCount: noQuestions,
    quizCount: noQuestions,
  );

  void bank(MockQuestionRepository q, List<StudentQuestion> items) {
    when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
      (_) async =>
          StudentQuestionPage(items: items, nextCursor: null, totalCount: items.length, accessibleCount: items.length),
    );
    when(() => q.check(any(), selectedOptionId: any(named: 'selectedOptionId'))).thenAnswer((i) async {
      final id = i.positionalArguments.first as String;
      final picked = i.namedArguments[#selectedOptionId] as String?;
      return CheckResult(
        isCorrect: picked == '$id-a',
        correctOptionId: '$id-a',
        correctAnswer: null,
        explanation: null,
      );
    });
  }

  group('V-Question', () {
    testWidgets('practice attempt: ✕ asks first; «واصل التدريب» stays, «خروج» leaves', (tester) async {
      final app = await open(
        tester,
        arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice)),
      );
      await push(app, tester, '/attempts/a1');
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);

      await tester.tap(find.byTooltip('خروج'));
      await tester.pumpAndSettle();
      expect(find.text('تقدّمك محفوظ'), findsOneWidget);
      expect(find.text('يمكنك المتابعة من السؤال 1 في أي وقت.'), findsOneWidget);
      await tester.tap(find.text('واصل التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);

      await tester.tap(find.byTooltip('خروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeAttemptScreen), findsNothing);
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);
    });

    testWidgets('question bank: the exit sheet says answers are kept (DECISIONS #13)', (tester) async {
      final app = await open(
        tester,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outline()),
        arrangeQuestions: (q) => bank(q, [mcq('الأول')]),
      );
      app.container.read(routerProvider).go('/subjects/p/questions');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);
      await tester.tap(find.byTooltip('خروج'));
      await tester.pumpAndSettle();
      expect(find.text(PracticeScreen.exitTitle), findsOneWidget);
      expect(find.text(PracticeScreen.exitMessage), findsOneWidget);
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.byType(QuestionsScreen), findsOneWidget);
    });

    testWidgets('the streak chip appears from 3 correct answers in a row and resets on a miss', (tester) async {
      final app = await open(
        tester,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outline()),
        arrangeQuestions: (q) => bank(q, [for (final n in _names) mcq(n)]),
      );
      app.container.read(routerProvider).go('/subjects/p/questions');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التدريب'));
      await tester.pumpAndSettle();

      Future<void> answer(String id, {required bool right}) async {
        await tester.tap(find.text(right ? 'صواب $id' : 'خطأ $id'));
        await tester.pump();
        await tester.tap(find.text('تحقق'));
        await tester.pumpAndSettle();
      }

      Future<void> next() async {
        final ok = find.widgetWithText(PlengoButton, 'متابعة');
        await tester.tap(ok.evaluate().isNotEmpty ? ok : find.widgetWithText(PlengoButton, 'فهمت، متابعة'));
        await tester.pumpAndSettle();
      }

      await answer('الأول', right: true);
      expect(find.byKey(const Key('correct-streak')), findsNothing);
      await next();
      await answer('الثاني', right: true);
      expect(find.byKey(const Key('correct-streak')), findsNothing);
      await next();
      await answer('الثالث', right: true);
      expect(find.text('3 إجابات صحيحة متتالية!'), findsOneWidget);
      await next();
      await answer('الرابع', right: false);
      expect(find.byKey(const Key('correct-streak')), findsNothing);
      expect(find.text('السؤال 4 من 5 · صحيحة 3 من 4'), findsOneWidget);
      await next();
      await answer('الخامس', right: true);
      expect(find.byKey(const Key('correct-streak')), findsNothing);
    });

    testWidgets('large text at 360 dp in dark mode lays out without overflow', (tester) async {
      final app = await open(
        tester,
        arrange: (l) {
          when(() => l.attempt('a1')).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice));
          when(() => l.check('a1', 'q1', any())).thenAnswer(
            (_) async => const CheckResult(
              isCorrect: false,
              correctOptionId: 'q1-a',
              correctAnswer: null,
              explanation: 'شرح طويل نسبياً يوضح لماذا كانت الإجابة الأولى هي الصحيحة في هذا السؤال.',
            ),
          );
        },
      );
      await app.container.read(appearanceProvider.notifier).setFontStep(2);
      await app.container.read(appearanceProvider.notifier).setThemeMode(ThemeMode.dark);
      app.container.read(routerProvider).go('/attempts/a1');
      await tester.pumpAndSettle();
      await narrow(tester);
      await tester.tap(find.text('خيار ب الأول'));
      await tester.pump();
      await tester.tap(find.text('تحقق'));
      await tester.pumpAndSettle();
      expect(find.text('ليست الإجابة الصحيحة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('V-Exam', () {
    testWidgets('grid cells show answered, unanswered, flagged and current, with a legend', (tester) async {
      final app = await open(
        tester,
        arrange: (l) {
          when(
            () => l.attempt('a1'),
          ).thenAnswer((_) async => attempt(questions: [question('q1'), question('q2'), question('الثالث')]));
          when(() => l.save('a1', any(), any())).thenAnswer((_) async => saved);
        },
      );
      await push(app, tester, '/attempts/a1');
      await tester.tap(find.text('خيار أ الأول'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('flag')));
      await tester.pumpAndSettle();
      expect(find.text('معلّم للمراجعة'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('السؤال 3 من 3 · أجبت عن 1'), findsOneWidget);

      await tester.tap(find.text('شبكة الأسئلة'));
      await tester.pumpAndSettle();
      Color fill(int i) => tester.widget<Material>(find.byKey(Key('grid-cell-$i'))).color!;
      expect(fill(0), PlengoColors.blue.base); // answered
      expect(fill(1), PlengoColors.orange.soft); // flagged
      expect(fill(2), PlengoColors.yellow.base); // current
      expect(find.text('2⚑'), findsOneWidget);
      expect(find.bySemanticsLabel('السؤال 1، مُجاب'), findsOneWidget);
      expect(find.bySemanticsLabel('السؤال 2، غير مُجاب، معلّم'), findsOneWidget);
      expect(find.bySemanticsLabel('السؤال 3، غير مُجاب، الحالي'), findsOneWidget);
      for (final legend in ['مُجاب', 'غير مُجاب', '⚑ معلّم', 'الحالي']) {
        expect(find.text(legend), findsOneWidget);
      }

      // An unanswered question that is not current is an outline.
      await tester.tap(find.byKey(const Key('grid-cell-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شبكة الأسئلة'));
      await tester.pumpAndSettle();
      expect(fill(2), isNot(PlengoColors.yellow.base));
      expect(find.bySemanticsLabel('السؤال 3، غير مُجاب'), findsOneWidget);

      // Review before finishing lists the unanswered and the flagged, and can jump back.
      await tester.tap(find.text('إنهاء الامتحان'));
      await tester.pumpAndSettle();
      expect(find.text('سؤالان بلا إجابة'), findsOneWidget);
      expect(find.text('1 معلّم للمراجعة'), findsOneWidget);
      await tester.tap(find.text('عودة إلى الأسئلة'));
      await tester.pumpAndSettle();
      expect(find.text('مراجعة قبل الإنهاء'), findsNothing);
      verifyNever(() => app.learning.submit(any(), any()));
    });

    testWidgets('✕ explains that the timer keeps running (DECISIONS #12)', (tester) async {
      final app = await open(tester, arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => attempt()));
      await push(app, tester, '/attempts/a1');
      await tester.tap(find.byTooltip('خروج'));
      await tester.pumpAndSettle();
      expect(find.text(ExamScreen.exitTitle), findsOneWidget);
      expect(find.text(ExamScreen.exitMessage), findsOneWidget);
      await tester.tap(find.text('واصل الامتحان'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamScreen), findsOneWidget);
      await tester.tap(find.byTooltip('خروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamScreen), findsNothing);
    });

    testWidgets('the timer turns red in the last minute', (tester) async {
      final app = await open(
        tester,
        arrange: (l) =>
            when(() => l.attempt('a1')).thenAnswer((_) async => attempt(deadlineAt: '2026-09-27T09:00:40.000Z')),
      );
      app.container.read(routerProvider).go('/attempts/a1');
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final chip = find.byType(ExamTimerChip);
      expect(chip, findsOneWidget);
      final box = tester.widget<Container>(find.descendant(of: chip, matching: find.byType(Container)).first);
      expect((box.decoration! as BoxDecoration).color, PlengoColors.red.soft);
      expect(find.bySemanticsLabel(RegExp('^الوقت المتبقي أقل من دقيقة')), findsOneWidget);
      // Leave the screen so the pulse and the ticker stop.
      app.container.read(routerProvider).go(Routes.home);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('large text at 360 dp: grid, review sheet and pending state fit', (tester) async {
      final app = await open(
        tester,
        arrange: (l) {
          when(
            () => l.attempt('a1'),
          ).thenAnswer((_) async => attempt(questions: [for (var i = 0; i < 12; i++) question('q$i')]));
          when(() => l.save('a1', any(), any())).thenAnswer((_) async => saved);
        },
      );
      await app.container.read(appearanceProvider.notifier).setFontStep(2);
      app.container.read(routerProvider).go('/attempts/a1');
      await tester.pumpAndSettle();
      await narrow(tester);
      await tester.tap(find.text('شبكة الأسئلة'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('grid-cell-11')), findsOneWidget);
      await tester.tap(find.text('إنهاء الامتحان'));
      await tester.pumpAndSettle();
      expect(find.text('12 سؤالاً بلا إجابة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('V-Results', () {
    Attempt withSkipped() => Attempt(
      attempt: summary(status: AttemptStatus.submitted, total: 3, correct: 1, wrong: 1, skipped: 1, score: 33),
      questions: [
        ...graded().questions,
        question('الثالث', result: correctResult),
      ],
      serverTime: '2026-09-27T09:10:00.000Z',
    );

    testWidgets('filters, state chips, answers and the daily goal', (tester) async {
      final app = await open(
        tester,
        arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => withSkipped()),
        arrangeHome: (h) => when(() => h.home()).thenAnswer(
          (_) async =>
              testHome(today: const Today(dueCards: 0, goal: 20, done: 12, goalMet: false, streak: 0, week: noWeek)),
        ),
      );
      app.container.read(routerProvider).go('/attempts/a1/results');
      await tester.pumpAndSettle();
      expect(find.text('واصل التدريب'), findsOneWidget); // 33%, no passing mark
      expect(find.text('هدف اليوم: 12 من 20'), findsOneWidget);
      expect(find.bySemanticsLabel('صحيحة: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('خاطئة: 1'), findsOneWidget);
      expect(find.bySemanticsLabel('متروكة: 1'), findsOneWidget);
      expect(find.text('✓ صحيحة'), findsOneWidget);
      expect(find.text('✗ خاطئة'), findsOneWidget);
      expect(find.text('متروكة'), findsWidgets);
      expect(find.text('⚑ معلّمة'), findsOneWidget);

      await tester.tap(find.text('المتروكة'));
      await tester.pumpAndSettle();
      expect(find.text('سؤال الثالث'), findsOneWidget);
      expect(find.text('سؤال الأول'), findsNothing);
      expect(find.text('سؤال الثاني'), findsNothing);

      await tester.tap(find.text('الخاطئة'));
      await tester.pumpAndSettle();
      expect(find.text('سؤال الثاني'), findsOneWidget);
      expect(find.text('سؤال الثالث'), findsNothing);

      await tester.tap(find.text('المعلّمة'));
      await tester.pumpAndSettle();
      expect(find.text('سؤال الثاني'), findsOneWidget);
      expect(find.text('سؤال الأول'), findsNothing);

      await tester.tap(find.text('الكل'));
      await tester.pumpAndSettle();
      expect(find.text('سؤال الأول'), findsOneWidget);
      expect(find.text('سؤال الثالث'), findsOneWidget);
    });

    testWidgets('a pass shows the passing mark', (tester) async {
      final passed = Attempt(
        attempt: AttemptSummary.fromJson({
          ...(jsonDecode(
                jsonEncode(
                  summary(status: AttemptStatus.submitted, total: 2, correct: 2, wrong: 0, skipped: 0, score: 100),
                ),
              )
              as Map<String, Object?>),
          'passed': true,
          'passingScorePercent': 60,
        }),
        questions: [question('q1', result: correctResult, selected: 'q1-a')],
        serverTime: '2026-09-27T09:10:00.000Z',
      );
      final app = await open(tester, arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => passed));
      app.container.read(routerProvider).go('/attempts/a1/results');
      await tester.pumpAndSettle();
      expect(find.text('أحسنت!'), findsOneWidget);
      expect(find.textContaining('ناجح — علامة النجاح'), findsOneWidget);
      expect(find.textContaining('أعد الأخطاء فقط'), findsNothing); // nothing wrong to retry
    });

    testWidgets('«متابعة» opens the streak moment once, then goes Home', (tester) async {
      final app = await open(
        tester,
        arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => graded()),
        arrangeHome: (h) => when(() => h.home()).thenAnswer(
          (_) async =>
              testHome(today: const Today(dueCards: 0, goal: 20, done: 20, goalMet: true, streak: 4, week: noWeek)),
        ),
      );
      app.container.read(routerProvider).go('/attempts/a1/results');
      await tester.pumpAndSettle();
      expect(find.text('أنجزت هدف اليوم: 20 من 20'), findsOneWidget);
      await tester.tap(find.byKey(const Key('results-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(StreakScreen), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(StreakScreen), matching: find.text('متابعة')));
      await tester.pumpAndSettle();
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);

      // Already shown today: straight Home.
      app.container.read(routerProvider).go('/attempts/a1/results');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('results-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(StreakScreen), findsNothing);
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);
    });

    testWidgets('large text at 360 dp in dark mode fits', (tester) async {
      final app = await open(
        tester,
        arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => withSkipped()),
      );
      await app.container.read(appearanceProvider.notifier).setFontStep(2);
      await app.container.read(appearanceProvider.notifier).setThemeMode(ThemeMode.dark);
      app.container.read(routerProvider).go('/attempts/a1/results');
      await tester.pumpAndSettle();
      await narrow(tester);
      expect(find.text('متابعة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('system back (DESIGN_SPEC §5: leaving never discards silently)', () {
    /// Android back button / iOS back swipe, as the platform sends it.
    Future<void> systemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('practice attempt: back opens the exit sheet; «واصل التدريب» stays, «خروج» leaves', (tester) async {
      final app = await open(
        tester,
        arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => attempt(mode: AttemptSummaryMode.practice)),
      );
      await push(app, tester, '/attempts/a1');
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);

      await systemBack(tester);
      expect(find.text(PracticeAttemptScreen.exitTitle), findsOneWidget);
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);
      await tester.tap(find.text('واصل التدريب'));
      await tester.pumpAndSettle();
      expect(find.text(PracticeAttemptScreen.exitTitle), findsNothing);
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);

      // Back while the sheet is open only closes the sheet.
      await systemBack(tester);
      expect(find.text(PracticeAttemptScreen.exitTitle), findsOneWidget);
      await systemBack(tester);
      expect(find.text(PracticeAttemptScreen.exitTitle), findsNothing);
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);

      await systemBack(tester);
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeAttemptScreen), findsNothing);
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);
    });

    testWidgets('question-bank practice: back opens the same exit sheet as ✕', (tester) async {
      final app = await open(
        tester,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outline()),
        arrangeQuestions: (q) => bank(q, [mcq('الأول'), mcq('الثاني')]),
      );
      app.container.read(routerProvider).go('/subjects/p/questions');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);

      await systemBack(tester);
      expect(find.text(PracticeScreen.exitTitle), findsOneWidget);
      expect(find.text(PracticeScreen.exitMessage), findsOneWidget);
      await tester.tap(find.text('واصل التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);

      await systemBack(tester);
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.byType(QuestionsScreen), findsOneWidget);
    });

    testWidgets('exam: back opens the timer exit sheet; «واصل الامتحان» stays, «خروج» leaves', (tester) async {
      final app = await open(tester, arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => attempt()));
      await push(app, tester, '/attempts/a1');
      expect(find.byType(ExamScreen), findsOneWidget);

      await systemBack(tester);
      expect(find.text(ExamScreen.exitTitle), findsOneWidget);
      expect(find.text(ExamScreen.exitMessage), findsOneWidget);
      await tester.tap(find.text('واصل الامتحان'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamScreen), findsOneWidget);

      await systemBack(tester);
      await tester.tap(find.widgetWithText(PlengoButton, 'خروج'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamScreen), findsNothing);
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);
    });

    testWidgets('exam waiting to be sent: back just leaves, with no sheet', (tester) async {
      final app = await open(tester, arrange: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => attempt()));
      await ExamStore(app.db).saveAttempt(attempt(), submitPending: true, timeSpentMs: 0);
      await push(app, tester, '/attempts/a1');
      expect(find.text('إرسال الآن'), findsOneWidget);

      await systemBack(tester);
      expect(find.text(ExamScreen.exitTitle), findsNothing);
      expect(find.byType(ExamScreen), findsNothing);
      expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, Routes.home);
    });
  });
}

/// 360 dp wide, after leaving Home (laid out by another screen group).
Future<void> narrow(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 740));
  await tester.pumpAndSettle();
}

const _names = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس'];

void unawaitedPush(PumpedApp app, String location) {
  app.container.read(routerProvider).push<void>(location).ignore();
}
