import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/app/theme.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/practice/practice_providers.dart';
import 'package:plengo/features/practice/practice_screen.dart';
import 'package:plengo/features/questions/question_providers.dart';
import 'package:plengo/features/questions/question_view.dart';
import 'package:plengo/features/quizzes/practice_attempt_screen.dart';
import 'package:plengo/features/quizzes/random_practice_screen.dart';
import 'package:plengo/features/reports/report_sheet.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';
import 'home_test.dart' show location;
import 'learning_test.dart' show offline, question, summary;

/// Filters as they go over the wire.
Map<String, Object?> wire(AttemptFilters f) => jsonDecode(jsonEncode(f)) as Map<String, Object?>;

const wrongWritten = CheckResult(
  isCorrect: false,
  correctOptionId: null,
  correctAnswer: 'بسبب الجاذبية الأرضية',
  explanation: null,
);

/// The feedback panel alone, in the app theme, right to left.
Future<void> pumpPanel(WidgetTester tester, Widget panel, {bool dark = false}) => tester.pumpWidget(
  ProviderScope(
    overrides: [contentReportsEnabledProvider.overrideWithValue(false)],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, app) => Directionality(textDirection: TextDirection.rtl, child: app!),
      home: Scaffold(body: Column(children: [const Spacer(), panel])),
    ),
  ),
);

/// Plengo v3 تدرّب (V3_PLAN §5) and the lesson page by question category (§3): the تدرّب page, the
/// practice setup and its attempt filters, written-answer self-grading and category rows.
void main() {
  setUpAll(() {
    registerFallbacks();
    registerFallbackValue(
      const StartAttemptRequest(
        clientAttemptId: '',
        source: StartAttemptRequestSource.random,
        mode: StartAttemptRequestMode.practice,
      ),
    );
    registerFallbackValue(const CheckAttemptAnswerRequest());
    registerFallbackValue(const SubmitAttemptRequest(answers: []));
  });

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Lesson lesson(String id, String title, String unitId) =>
      Lesson(id: id, subjectId: 'p', unitId: unitId, code: id, titleAr: title, sortOrder: 0);

  SubjectOutline outline({bool access = true}) => SubjectOutline(
    subject: subject('p', 'العلوم'),
    units: [
      UnitWithLessons(
        id: 'u1',
        subjectId: 'p',
        code: 'u1',
        titleAr: 'الوحدة الأولى',
        sortOrder: 0,
        lessons: [lesson('l1', 'مقدمة في الخلية', 'u1'), lesson('l2', 'تركيب الخلية', 'u1')],
      ),
      UnitWithLessons(
        id: 'u2',
        subjectId: 'p',
        code: 'u2',
        titleAr: 'الوحدة الثانية',
        sortOrder: 1,
        lessons: [lesson('l3', 'الوراثة', 'u2')],
      ),
    ],
    lessons: const [],
    tracks: const [],
    access: access ? permanentAccess : noAccess,
    questionCount: const ContentCount(total: 10, free: 2),
    deckCount: noQuestions,
    quizCount: noQuestions,
  );

  StudentQuestionCategory category(String id, String name, int count, {String? parentId, int? accessible}) =>
      StudentQuestionCategory(
        id: id,
        subjectId: null,
        parentId: parentId,
        code: id,
        nameAr: name,
        sortOrder: 0,
        questionCount: count,
        accessibleCount: accessible ?? count,
      );

  StudentQuestionCategoryList categories({bool locked = false}) => StudentQuestionCategoryList(
    items: [
      category('c1', 'علّل', 3, accessible: locked ? 0 : null),
      category('c2', 'قارن', 0),
      category('c3', 'قارن بين الخلايا', 2, parentId: 'c2', accessible: locked ? 0 : null),
      category('c4', 'رتّب', 0),
    ],
    uncategorized: Uncategorized(questionCount: 1, accessibleCount: locked ? 0 : 1),
  );

  group('practice helpers', () {
    test('categories group under their parent; empty ones are hidden; counts include children', () {
      final groups = groupCategories(categories().items);
      expect([for (final g in groups) g.id], ['c1', 'c2']);
      expect(groups[1].children.map((c) => c.id), ['c3']);
      expect(groups[1].questionCount, 2);
      expect(groupCategories(categories().items, keepEmpty: true).map((g) => g.id), ['c1', 'c2', 'c4']);
    });

    test('lists of several lessons add up', () {
      final merged = mergeCategoryLists([categories(), categories()]);
      expect(merged.items.map((c) => c.questionCount), [6, 0, 4, 0]);
      expect(merged.uncategorized.questionCount, 2);
    });

    test('a selected parent covers its children; counts follow the selection', () {
      final groups = groupCategories(categories().items);
      expect(effectiveCategoryIds(groups, {'c2', 'c3'}), ['c2']);
      expect(effectiveCategoryIds(groups, {'c3', 'c4'}), ['c3']); // c4 has no questions here
      expect(matchingCount(categories(), const []), (accessible: 6, total: 6));
      expect(matchingCount(categories(), const ['c2']), (accessible: 2, total: 2));
      expect(matchingCount(categories(locked: true), const ['c1']), (accessible: 0, total: 3));
    });

    test('filters: some lessons → lessonIds; every lesson → the unit alone; «جميع الأسئلة» → allQuestions', () {
      final some = practiceFilters(
        subjectId: 'p',
        unitId: 'u1',
        scopeLessonIds: const ['l1', 'l2'],
        selectedLessonIds: const {'l2'},
        categoryIds: const ['c1', 'c3'],
        types: const {AttemptFiltersTypes.written, AttemptFiltersTypes.mcq},
        count: 20,
      );
      expect(wire(some), {
        'subjectId': 'p',
        'unitId': 'u1',
        'lessonIds': ['l2'],
        'categoryIds': ['c1', 'c3'],
        'types': ['mcq', 'written'],
        'count': 20,
      });
      final all = practiceFilters(
        subjectId: 'p',
        unitId: null,
        scopeLessonIds: const ['l1', 'l2', 'l3'],
        selectedLessonIds: const {'l1', 'l2', 'l3'},
        categoryIds: const [],
        types: const {},
        count: practiceAllQuestions,
      );
      expect(wire(all), {'subjectId': 'p', 'allQuestions': true});
    });
  });

  Future<PumpedApp> pumpPractice(
    WidgetTester tester, {
    bool locked = false,
    void Function(MockLearningRepository)? arrangeLearning,
    void Function(MockQuestionRepository)? arrangeQuestions,
  }) => pumpApp(
    tester,
    signedInAs: testMe,
    arrangeCatalog: (c) {
      when(() => c.subjects(any())).thenAnswer(
        (_) async => [
          catalogSubject('p', 'العلوم', hasAccess: !locked),
          catalogSubject('m', 'الرياضيات', hasAccess: true),
        ],
      );
      when(() => c.outline('p')).thenAnswer((_) async => outline(access: !locked));
    },
    arrangeQuestions: (q) {
      when(() => q.categories(any())).thenAnswer((_) async => categories(locked: locked));
      arrangeQuestions?.call(q);
    },
    arrangeLearning: arrangeLearning,
  );

  group('تدرّب', () {
    testWidgets('the page lists the stage subjects (locked ones stay open) and «رسمات العلوم»', (tester) async {
      useSize(tester, const Size(390, 1200));
      final app = await pumpPractice(tester, locked: true);
      app.container.read(routerProvider).go(Routes.practice);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('practice.header.drawn')), findsOneWidget);
      expect(find.text('اختبارات بلينغو المخصصة'), findsOneWidget);
      final query = verify(() => app.catalog.subjects(captureAny())).captured.last;
      expect(query, (levelId: 'l12', universityId: null, facultyId: null, academicYearId: null));
      final science = find.byKey(const Key('practice.subject.p'));
      expect(find.descendant(of: science, matching: find.text('مقفل')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('practice.subject.m')), matching: find.text('مقفل')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('practice.diagrams')));
      await tester.pumpAndSettle();
      expect(location(app), Routes.practiceDiagrams);

      app.container.read(routerProvider).go(Routes.practice);
      await tester.pumpAndSettle();
      await tester.tap(science);
      await tester.pumpAndSettle();
      expect(location(app), '/practice/p');
      expect(find.byType(PracticeSetupScreen), findsOneWidget);
    });

    testWidgets('setup → the attempt request carries the unit, lessons, categories, types and count', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpPractice(
        tester,
        arrangeLearning: (l) {
          when(() => l.start(any())).thenAnswer(
            (_) async => Attempt(
              attempt: summary(id: 'a9', mode: AttemptSummaryMode.practice),
              questions: [question('q1')],
              serverTime: '2026-09-27T09:00:00.000Z',
            ),
          );
          when(() => l.attempt('a9')).thenAnswer(
            (_) async => Attempt(
              attempt: summary(id: 'a9', mode: AttemptSummaryMode.practice),
              questions: [question('q1')],
              serverTime: '2026-09-27T09:00:00.000Z',
            ),
          );
        },
      );
      app.container.read(routerProvider).go('/practice/p');
      await tester.pumpAndSettle();
      // Every unit and lesson to start with; the hidden empty category is not offered.
      expect(find.text('كل الوحدات'), findsOneWidget);
      expect(find.byKey(const Key('practice.lesson.l3')), findsOneWidget);
      expect(find.byKey(const Key('practice.category.c4')), findsNothing);
      expect(find.text('متاح لهذا الاختيار: 6 أسئلة'), findsOneWidget);

      await tester.tap(
        find.descendant(of: find.byKey(const Key('practice.units')), matching: find.text('الوحدة الأولى')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('practice.lesson.l3')), findsNothing);
      await tester.tap(find.byKey(const Key('practice.lesson.l2')));
      await tester.pumpAndSettle();
      // One lesson chosen: categories are counted for that lesson.
      expect(verify(() => app.questions.categories(captureAny())).captured.last, (
        subjectId: 'p',
        teacherTrackId: null,
        unitId: null,
        lessonId: 'l1',
      ));
      await tester.tap(find.byKey(const Key('practice.category.c1')));
      await tester.tap(find.byKey(const Key('practice.category.c2')));
      await tester.pumpAndSettle();
      // The parent covers its child.
      expect(tester.widget<ToggleChip>(find.byKey(const Key('practice.category.c3'))).onTap, isNull);
      await tester.tap(find.byKey(const Key('practice.type.written')));
      await tester.tap(find.text('جميع الأسئلة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('practice.start')));
      await tester.pumpAndSettle();

      final body = verify(() => app.learning.start(captureAny())).captured.single as StartAttemptRequest;
      expect(body.source, StartAttemptRequestSource.random);
      expect(body.mode, StartAttemptRequestMode.practice);
      expect(wire(body.filters!), {
        'subjectId': 'p',
        'unitId': 'u1',
        'lessonIds': ['l1'],
        'categoryIds': ['c1', 'c2'],
        'types': ['written'],
        'allQuestions': true,
      });
      expect(find.byType(PracticeAttemptScreen), findsOneWidget);
    });

    testWidgets('a count of 10 is sent as count; the old random practice is still one tap away', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpPractice(
        tester,
        arrangeLearning: (l) =>
            when(() => l.start(any())).thenThrow(const ApiException('VALIDATION_ERROR', 'no_questions')),
      );
      app.container.read(routerProvider).go('/practice/p');
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('practice.start')));
      await tester.pumpAndSettle();
      final body = verify(() => app.learning.start(captureAny())).captured.single as StartAttemptRequest;
      expect(wire(body.filters!), {'subjectId': 'p', 'count': 10});
      // The server found nothing (e.g. no written questions): the reason shows above the button.
      expect(find.text('لا توجد أسئلة متاحة تطابق هذه الاختيارات'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice.random')));
      await tester.pumpAndSettle();
      expect(tester.widget<RandomPracticeScreen>(find.byType(RandomPracticeScreen)).subjectId, 'p');
    });

    testWidgets('start is disabled with a reason: no lesson chosen, or only locked questions', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpPractice(tester, locked: true);
      app.container.read(routerProvider).go('/practice/p');
      await tester.pumpAndSettle();
      PlengoButton start() => tester.widget(find.byKey(const Key('practice.start')));
      expect(find.text('أسئلة هذا الاختيار تحتاج إلى تفعيل'), findsOneWidget);
      expect(start().onPressed, isNull);
      expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);

      await tester.tap(find.byKey(const Key('practice.lessons.all')));
      await tester.pumpAndSettle();
      expect(find.text('اختر درساً واحداً على الأقل'), findsOneWidget);
      expect(start().onPressed, isNull);
    });

    testWidgets('categories that cannot load offline leave the rest of the setup usable', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpPractice(
        tester,
        arrangeQuestions: (q) => when(() => q.categories(any())).thenThrow(offline),
      );
      app.container.read(routerProvider).go('/practice/p');
      await tester.pumpAndSettle();
      expect(find.text('تحتاج التصنيفات إلى اتصال بالإنترنت'), findsOneWidget);
      expect(tester.widget<PlengoButton>(find.byKey(const Key('practice.start'))).onPressed, isNotNull);
    });
  });

  group('written answers: «إجابتي صحيحة لكن بصياغة مختلفة»', () {
    AttemptQuestion written(String id) => AttemptQuestion(
      questionId: id,
      type: AttemptQuestionType.written,
      unitId: null,
      lessonId: null,
      questionText: 'علّل سقوط الأجسام',
      options: const [],
      selectedOptionId: null,
      writtenAnswer: null,
      flagged: false,
      markedCorrectByStudent: false,
      answeredAt: null,
      timeSpentMs: null,
      result: null,
    );

    testWidgets('practice attempt: the server records it; score and the in-a-row chip count it', (tester) async {
      useSize(tester, const Size(390, 1000));
      final attempt = Attempt(
        attempt: summary(id: 'a5', mode: AttemptSummaryMode.practice, total: 3),
        questions: [question('q1'), question('q2'), written('w3')],
        serverTime: '2026-09-27T09:00:00.000Z',
      );
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeLearning: (l) {
          when(() => l.attempt('a5')).thenAnswer((_) async => attempt);
          when(() => l.check('a5', any(), any())).thenAnswer(
            (i) async => i.positionalArguments[1] == 'w3'
                ? wrongWritten
                : CheckResult(
                    isCorrect: true,
                    correctOptionId: '${i.positionalArguments[1]}-a',
                    correctAnswer: null,
                    explanation: null,
                  ),
          );
          when(() => l.markCorrect('a5', 'w3')).thenAnswer(
            (_) async => MarkAnswerCorrectResult(
              questionId: 'w3',
              result: const CheckResult(
                isCorrect: true,
                correctOptionId: null,
                correctAnswer: 'بسبب الجاذبية الأرضية',
                explanation: null,
              ),
              attempt: summary(id: 'a5', mode: AttemptSummaryMode.practice, total: 3),
            ),
          );
        },
      );
      app.container.read(routerProvider).push<void>('/attempts/a5').ignore();
      await tester.pumpAndSettle();
      for (final id in ['q1', 'q2']) {
        await tester.tap(find.textContaining('خيار أ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تحقق'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('selfgrade.correct')), findsNothing, reason: id);
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byKey(const Key('written-answer')), 'الجاذبية');
      await tester.pump();
      await tester.tap(find.text('تحقق'));
      await tester.pumpAndSettle();
      expect(find.text('الإجابة النموذجية: '), findsOneWidget);
      expect(find.text('بسبب الجاذبية الأرضية'), findsOneWidget);
      expect(find.text(AnswerFeedbackPanel.selfGradeWrongLabel), findsOneWidget);
      expect(find.textContaining('صحيحة 2 من 3'), findsOneWidget);
      expect(find.byKey(const Key('correct-streak')), findsNothing);

      await tester.tap(find.byKey(const Key('selfgrade.correct')));
      await tester.pumpAndSettle();
      verify(() => app.learning.markCorrect('a5', 'w3')).called(1);
      expect(find.text(AnswerFeedbackPanel.markedCorrectTitle), findsOneWidget);
      expect(find.textContaining('صحيحة 3 من 3'), findsOneWidget);
      expect(find.text('3 إجابات صحيحة متتالية!'), findsOneWidget);
      expect(find.byKey(const Key('selfgrade.correct')), findsNothing);
      expect(find.text('عرض النتيجة'), findsOneWidget);
    });

    testWidgets('question bank: «إجابتي صحيحة…» counts in the session score; «إجابتي خاطئة» moves on', (tester) async {
      useSize(tester, const Size(390, 1000));
      StudentQuestion bankWritten(String id) => StudentQuestion(
        id: id,
        type: StudentQuestionType.written,
        subjectId: 'p',
        teacherTrackId: null,
        unitId: null,
        lessonId: null,
        categoryId: null,
        sortOrder: 0,
        difficulty: null,
        isFree: true,
        locked: false,
        questionText: 'سؤال مكتوب ${const {'b1': 'الأول', 'b2': 'الثاني', 'b3': 'الثالث'}[id]}',
        options: null,
      );
      final items = [bankWritten('b1'), bankWritten('b2'), bankWritten('b3')];
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outline()),
        arrangeQuestions: (q) {
          when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
            (_) async => StudentQuestionPage(items: items, nextCursor: null, totalCount: 3, accessibleCount: 3),
          );
          when(
            () => q.check(
              any(),
              selectedOptionId: any(named: 'selectedOptionId'),
              writtenAnswer: any(named: 'writtenAnswer'),
            ),
          ).thenAnswer((_) async => wrongWritten);
        },
      );
      app.container.read(routerProvider).go('/subjects/p/questions');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);

      Future<void> answer() async {
        await tester.enterText(find.byKey(const Key('written-answer')), 'جواب');
        await tester.pump();
        await tester.tap(find.text('تحقق'));
        await tester.pumpAndSettle();
      }

      await answer();
      expect(find.textContaining('صحيحة 0 من 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('selfgrade.correct')));
      await tester.pumpAndSettle();
      expect(find.text(AnswerFeedbackPanel.markedCorrectTitle), findsOneWidget);
      expect(find.textContaining('صحيحة 1 من 1'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      await answer();
      await tester.tap(find.byKey(const Key('selfgrade.wrong')));
      await tester.pumpAndSettle();
      expect(find.text('سؤال مكتوب الثالث'), findsOneWidget);
      expect(find.textContaining('صحيحة 1 من 2'), findsOneWidget);
    });

    testWidgets('choice questions and exams never offer it', (tester) async {
      // A choice question (not written) keeps the single continue button.
      await pumpPanel(
        tester,
        AnswerFeedbackPanel(
          result: const CheckResult(isCorrect: false, correctOptionId: 'a', correctAnswer: null, explanation: null),
          questionId: 'q',
          onContinue: () {},
          onSelfGradeCorrect: () {},
        ),
      );
      expect(find.byKey(const Key('selfgrade.correct')), findsNothing);
      expect(find.text('فهمت، متابعة'), findsOneWidget);
      // Without the callback (exam results, review) a written answer has no self-grade either.
      await pumpPanel(
        tester,
        AnswerFeedbackPanel(result: wrongWritten, questionId: 'q', written: true, onContinue: () {}),
      );
      expect(find.byKey(const Key('selfgrade.correct')), findsNothing);
      expect(find.text('الإجابة النموذجية: '), findsOneWidget);
    });

    testWidgets('results show the answers the student corrected', (tester) async {
      useSize(tester, const Size(390, 2400));
      final w = written('w1');
      final done = Attempt(
        attempt: summary(
          id: 'a6',
          mode: AttemptSummaryMode.practice,
          status: AttemptStatus.submitted,
          total: 1,
          correct: 1,
          wrong: 0,
          skipped: 0,
          score: 100,
        ),
        questions: [
          AttemptQuestion(
            questionId: w.questionId,
            type: w.type,
            unitId: null,
            lessonId: null,
            questionText: w.questionText,
            options: const [],
            selectedOptionId: null,
            writtenAnswer: 'الجاذبية',
            flagged: false,
            markedCorrectByStudent: true,
            answeredAt: '2026-09-27T09:05:00.000Z',
            timeSpentMs: 1000,
            result: const CheckResult(
              isCorrect: true,
              correctOptionId: null,
              correctAnswer: 'بسبب الجاذبية الأرضية',
              explanation: null,
            ),
          ),
        ],
        serverTime: '2026-09-27T09:10:00.000Z',
      );
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeLearning: (l) => when(() => l.attempt('a6')).thenAnswer((_) async => done),
      );
      app.container.read(routerProvider).push<void>('/attempts/a6/results').ignore();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('result.markedCorrect')), findsOneWidget);
      expect(find.text('صحّحتها بنفسك'), findsOneWidget);
    });
  });

  group('lesson page by question category (v3 §3)', () {
    StudentQuestion bankQuestion(String id, {String? categoryId}) => StudentQuestion(
      id: id,
      type: StudentQuestionType.mcq,
      subjectId: 'p',
      teacherTrackId: null,
      unitId: 'u1',
      lessonId: 'l1',
      categoryId: categoryId,
      sortOrder: 0,
      difficulty: null,
      isFree: true,
      locked: false,
      questionText: 'سؤال $id',
      options: const [
        StudentOption(id: 'a', text: 'أ'),
        StudentOption(id: 'b', text: 'ب'),
      ],
    );

    Future<PumpedApp> openLesson(WidgetTester tester) =>
        pumpPractice(
          tester,
          arrangeQuestions: (q) {
            when(
              () => q.page(
                any(),
                cursor: any(named: 'cursor'),
                categoryIds: any(named: 'categoryIds'),
              ),
            ).thenAnswer((i) async {
              final ids = i.namedArguments[#categoryIds] as String?;
              final items = [
                bankQuestion('x1', categoryId: 'c1'),
                bankQuestion('x2', categoryId: 'c3'),
                bankQuestion('x3'),
              ].where((q) => ids == null || ids.split(',').contains(q.categoryId)).toList();
              return StudentQuestionPage(
                items: items,
                nextCursor: null,
                totalCount: items.length,
                accessibleCount: items.length,
              );
            });
          },
          arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
        ).then((app) {
          when(() => app.flashcards.decks(any())).thenAnswer((_) async => const []);
          return app;
        });

    testWidgets('categories show as rows with counts, children nested, the rest «أسئلة أخرى»', (tester) async {
      useSize(tester, const Size(390, 1400));
      final app = await openLesson(tester);
      app.container.read(routerProvider).go('/subjects/p/lessons/l1');
      await tester.pumpAndSettle();
      expect(verify(() => app.questions.categories(captureAny())).captured.last, (
        subjectId: 'p',
        teacherTrackId: null,
        unitId: null,
        lessonId: 'l1',
      ));
      expect(find.text('حسب نوع السؤال'), findsOneWidget);
      for (final key in ['c1', 'c2', 'c3', 'other']) {
        expect(find.byKey(Key('lesson.category.$key')), findsOneWidget, reason: key);
      }
      expect(find.byKey(const Key('lesson.category.c4')), findsNothing);
      expect(find.bySemanticsLabel('قارن، سؤالان'), findsOneWidget);
      expect(find.bySemanticsLabel('أسئلة أخرى، سؤال واحد'), findsOneWidget);
      // The child sits under its parent, indented towards the end (left in RTL).
      Offset corner(String key) =>
          tester.getTopRight(find.descendant(of: find.byKey(Key(key)), matching: find.byType(InkWell)).first);
      final parent = corner('lesson.category.c2');
      final child = corner('lesson.category.c3');
      expect(child.dy, greaterThan(parent.dy));
      expect(child.dx, lessThan(parent.dx));
    });

    testWidgets('tapping a category opens its questions; «أسئلة أخرى» those without one', (tester) async {
      useSize(tester, const Size(390, 1400));
      final app = await openLesson(tester);
      final router = app.container.read(routerProvider);
      router.go('/subjects/p/lessons/l1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson.category.c3')));
      await tester.pumpAndSettle();
      expect(location(app), '/subjects/p/questions?lessonId=l1&categoryIds=c3');
      expect(
        verify(
          () => app.questions.page(
            any(),
            cursor: any(named: 'cursor'),
            categoryIds: captureAny(named: 'categoryIds'),
          ),
        ).captured,
        contains('c3'),
      );
      expect(find.text('قارن بين الخلايا'), findsOneWidget); // the title
      expect(find.textContaining('x2'), findsOneWidget);
      expect(find.textContaining('x1'), findsNothing);

      router.go('/subjects/p/lessons/l1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson.category.other')));
      await tester.pumpAndSettle();
      expect(location(app), '/subjects/p/questions?lessonId=l1&categoryIds=$uncategorizedCategory');
      expect(find.text('أسئلة أخرى'), findsOneWidget);
      expect(find.textContaining('x3'), findsOneWidget);
      expect(find.textContaining('x1'), findsNothing);
    });
  });

  group('360 × 800, large text', () {
    for (final dark in [false, true]) {
      testWidgets('تدرّب, setup, lesson categories and self-grade lay out (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        useSize(tester, const Size(360, 800));
        tester.platformDispatcher.textScaleFactorTestValue = 1.16;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final app = await pumpPractice(
          tester,
          arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
          arrangeQuestions: (q) => when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
            (_) async => const StudentQuestionPage(items: [], nextCursor: null, totalCount: 3, accessibleCount: 3),
          ),
        );
        when(() => app.flashcards.decks(any())).thenAnswer((_) async => const []);
        final router = app.container.read(routerProvider);
        for (final path in [Routes.practice, '/practice/p', '/subjects/p/lessons/l1']) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
          final scrollable = find.byType(Scrollable).first;
          await tester.drag(scrollable, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        router.go('/practice/p');
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: find.byKey(const Key('practice.units')), matching: find.text('الوحدة الأولى')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await pumpPanel(
          tester,
          AnswerFeedbackPanel(
            result: wrongWritten,
            questionId: 'w',
            written: true,
            onContinue: () {},
            onSelfGradeCorrect: () {},
          ),
          dark: dark,
        );
        await tester.pumpAndSettle();
        expect(find.text(AnswerFeedbackPanel.selfGradeCorrectLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
