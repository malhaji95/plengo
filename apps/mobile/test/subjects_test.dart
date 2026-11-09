import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/account/placement_screen.dart';
import 'package:plengo/features/subjects/learning_path.dart';
import 'package:plengo/features/subjects/subject_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

/// A phone screen in logical pixels.
void phoneSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openSubjectsTab(WidgetTester tester) async {
  await tester.tap(find.text('المواد').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerFallbacks);

  testWidgets('opens on the student level, and every level is browsable (spec §8.9)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer((inv) async {
          final q =
              inv.positionalArguments.first
                  as ({String levelId, String? universityId, String? facultyId, String? academicYearId});
          return q.levelId == 'l12'
              ? [catalogSubject('p', 'الفيزياء', description: 'فيزياء البكالوريا'), catalogSubject('m', 'الرياضيات')]
              : [catalogSubject('g9', 'العلوم', levelId: 'l9')];
        });
      },
    );
    await openSubjectsTab(tester);

    final chip = tester.widget<PlengoPill>(fieldByKey('level.grade-12'));
    expect(chip.selected, isTrue);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.text('فيزياء البكالوريا'), findsOneWidget);

    await tester.tap(fieldByKey('level.grade-9'));
    await tester.pumpAndSettle();
    expect(find.text('العلوم'), findsOneWidget);
    expect(find.text('الفيزياء'), findsNothing);
    verify(
      () => app.catalog.subjects((levelId: 'l9', universityId: null, facultyId: null, academicYearId: null)),
    ).called(1);
  });

  testWidgets('the college level shows the optional university filter', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.universities()).thenAnswer(
        (_) async => const [University(id: 'u1', code: 'damascus', nameAr: 'جامعة دمشق', sortOrder: 0, isActive: true)],
      ),
    );
    await openSubjectsTab(tester);
    expect(fieldByKey('filter.university'), findsNothing);
    await tester.tap(fieldByKey('level.college'));
    await tester.pumpAndSettle();
    expect(fieldByKey('filter.university'), findsOneWidget);
    expect(find.text('لا توجد مواد هنا بعد'), findsOneWidget);
  });

  testWidgets('a subject opens its outline: units with lessons, then general lessons', (tester) async {
    Lesson lesson(String id, String title, {String? unitId}) =>
        Lesson(id: id, subjectId: 'p', unitId: unitId, code: id, titleAr: title, sortOrder: 0);
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer((_) async => [catalogSubject('p', 'الفيزياء')]);
        when(() => c.outline('p')).thenAnswer(
          (_) async => SubjectOutline(
            subject: subject('p', 'الفيزياء'),
            units: [
              UnitWithLessons(
                id: 'u1',
                subjectId: 'p',
                code: 'mech',
                titleAr: 'الميكانيك',
                sortOrder: 0,
                lessons: [
                  lesson('l1', 'الحركة', unitId: 'u1'),
                  lesson('l2', 'القوى', unitId: 'u1'),
                ],
              ),
            ],
            lessons: [lesson('l0', 'مراجعة عامة')],
            access: noAccess,
            questionCount: noQuestions,
            deckCount: noQuestions,
            quizCount: noQuestions,
            tracks: const [],
          ),
        );
      },
    );
    await openSubjectsTab(tester);
    await tester.tap(find.text('الفيزياء'));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectScreen), findsOneWidget);
    expect(find.text('الميكانيك'), findsOneWidget);
    expect(find.text('درسان'), findsOneWidget);
    expect(find.text('الحركة'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('مراجعة عامة'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('دروس عامة'), findsOneWidget);
    expect(find.text('مراجعة عامة'), findsOneWidget);
  });

  testWidgets('changing the placement in settings saves it and updates the profile', (tester) async {
    const updated = Me(
      id: 'u1',
      email: 'student@example.com',
      emailVerified: true,
      role: MeRole.student,
      fullName: 'سارة أحمد',
      educationLevelId: 'l9',
      universityId: null,
      facultyId: null,
      academicYearId: null,
      avatarUrl: null,
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.updatePlacement(any())).thenAnswer((_) async => updated),
    );
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('المرحلة التعليمية'));
    await tester.pumpAndSettle();
    expect(find.byType(PlacementScreen), findsOneWidget);

    await tester.tap(fieldByKey('placement.level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الصف التاسع').last);
    await tester.pumpAndSettle();
    await tester.tap(fieldByKey('placement.save'));
    await tester.pumpAndSettle();

    verify(
      () => app.catalog.updatePlacement((levelId: 'l9', universityId: null, facultyId: null, academicYearId: null)),
    ).called(1);
    expect(find.byType(PlacementScreen), findsNothing);
    expect(app.container.read(authControllerProvider).value?.educationLevelId, 'l9');
  });

  group('learning path node states (DECISIONS #7)', () {
    Lesson l(String id) => Lesson(id: id, subjectId: 'p', unitId: 'u1', code: id, titleAr: id, sortOrder: 0);
    final lessons = [l('a'), l('b'), l('c'), l('d')];

    test('100 % is done; the first lesson below 100 % is current; the rest are upcoming', () {
      expect(pathNodeStates(lessons: lessons, percents: {'a': 100, 'b': 40}), {
        'a': PathNodeState.done,
        'b': PathNodeState.current,
        'c': PathNodeState.upcoming,
        'd': PathNodeState.upcoming,
      });
    });

    test('the resume lesson is current even when an earlier lesson is unfinished', () {
      final states = pathNodeStates(lessons: lessons, percents: {'a': 100, 'b': 40}, resumeLessonId: 'c');
      expect(states['b'], PathNodeState.upcoming);
      expect(states['c'], PathNodeState.current);
    });

    test('a finished resume lesson stays done; a resume lesson of another subject is ignored', () {
      expect(
        pathNodeStates(lessons: lessons, percents: {'a': 100}, resumeLessonId: 'a'),
        containsPair('b', PathNodeState.current),
      );
      expect(
        pathNodeStates(lessons: lessons, percents: const {}, resumeLessonId: 'elsewhere'),
        containsPair('a', PathNodeState.current),
      );
    });

    test('everything done: no current node', () {
      final states = pathNodeStates(lessons: lessons, percents: {for (final x in lessons) x.id: 100});
      expect(states.values.toSet(), {PathNodeState.done});
    });

    test('the resume lesson comes from the newest item of this subject, not a track', () {
      ResumeItem r(String subjectId, String? lessonId, {String? track}) => ResumeItem(
        subjectId: subjectId,
        subjectNameAr: '',
        teacherTrackId: track,
        trackTitleAr: null,
        unitId: null,
        unitNameAr: null,
        lessonId: lessonId,
        lessonNameAr: null,
        activityType: ResumeItemActivityType.question,
        itemId: null,
        itemTitleAr: null,
        attemptId: null,
        lastActivityAt: '2026-09-27T09:00:00.000Z',
      );
      expect(resumeLessonId('p', [r('m', 'x'), r('p', 'y', track: 't'), r('p', 'b'), r('p', 'c')]), 'b');
      expect(resumeLessonId('p', null), isNull);
    });

    test('unit and completed-units labels follow Arabic number agreement', () {
      expect([1, 2, 3, 11].map(completedUnitsLabel), [
        'وحدة واحدة مكتملة',
        'الوحدتان مكتملتان',
        '3 وحدات مكتملة',
        '11 وحدة مكتملة',
      ]);
    });
  });

  testWidgets('locked subjects carry a lock and «مقفل»; the code row opens redeem (DECISIONS #1)', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(
        () => c.subjects(any()),
      ).thenAnswer((_) async => [catalogSubject('p', 'الفيزياء', hasAccess: true), catalogSubject('a', 'العربية')]),
    );
    await openSubjectsTab(tester);
    final open = find.byKey(const Key('subject.p'));
    final locked = find.byKey(const Key('subject.a'));
    expect(find.descendant(of: open, matching: find.text('مقفل')), findsNothing);
    expect(find.descendant(of: locked, matching: find.text('مقفل')), findsOneWidget);
    expect(find.descendant(of: locked, matching: find.byIcon(Icons.lock_rounded)), findsOneWidget);

    await tester.tap(find.text('لديك كود تفعيل؟'));
    await tester.pumpAndSettle();
    expect(find.byType(RedeemScreen), findsOneWidget);
  });

  testWidgets('without COUPON_REDEMPTION the subjects tab has no code row', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      couponRedemption: false,
      arrangeCatalog: (c) => when(() => c.subjects(any())).thenAnswer((_) async => [catalogSubject('a', 'العربية')]),
    );
    await openSubjectsTab(tester);
    expect(find.text('مقفل'), findsOneWidget);
    expect(find.text('لديك كود تفعيل؟'), findsNothing);
  });

  testWidgets('learning path: completed units collapse, the current unit shows done / current / upcoming / quiz', (
    tester,
  ) async {
    phoneSize(tester, const Size(360, 2000));
    Lesson lesson(String id, String title, String unitId) =>
        Lesson(id: id, subjectId: 'p', unitId: unitId, code: id, titleAr: title, sortOrder: 0);
    LessonProgress done(String id, int pct, {int questions = 0}) => LessonProgress(
      questionsAttempted: 0,
      questionsCorrect: 0,
      questionsTotal: questions,
      quizzesCompleted: 0,
      quizzesTotal: 0,
      flashcardsStudied: 0,
      flashcardsTotal: 0,
      completionPercent: pct,
      lessonId: id,
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => SubjectOutline(
          subject: subject('p', 'الفيزياء'),
          units: [
            UnitWithLessons(
              id: 'u1',
              subjectId: 'p',
              code: 'u1',
              titleAr: 'الحركة',
              sortOrder: 0,
              lessons: [lesson('l1', 'السرعة', 'u1')],
            ),
            UnitWithLessons(
              id: 'u2',
              subjectId: 'p',
              code: 'u2',
              titleAr: 'الكهرباء',
              sortOrder: 1,
              lessons: [lesson('l2', 'التيار', 'u2'), lesson('l3', 'المقاومة', 'u2'), lesson('l4', 'الدارات', 'u2')],
            ),
          ],
          lessons: const [],
          access: noAccess,
          questionCount: noQuestions,
          deckCount: noQuestions,
          quizCount: noQuestions,
          tracks: const [],
        ),
      ),
      arrangeLearning: (l) {
        when(() => l.progress('p', teacherTrackId: null)).thenAnswer(
          (_) async => ScopeProgress(
            questionsAttempted: 0,
            questionsCorrect: 0,
            questionsTotal: 0,
            quizzesCompleted: 0,
            quizzesTotal: 0,
            flashcardsStudied: 0,
            flashcardsTotal: 0,
            completionPercent: 50,
            subjectId: 'p',
            teacherTrackId: null,
            lastActivityAt: null,
            units: const [],
            lessons: [done('l1', 100), done('l2', 100), done('l3', 30, questions: 12)],
          ),
        );
        when(() => l.quizzes(any())).thenAnswer(
          (_) async => [
            const StudentQuiz(
              id: 'qz',
              subjectId: 'p',
              teacherTrackId: null,
              unitId: 'u2',
              lessonId: null,
              titleAr: 'اختبار الكهرباء',
              description: null,
              allowedModes: StudentQuizAllowedModes.both,
              timeLimitSeconds: 1800,
              passingScorePercent: 60,
              maxAttempts: null,
              isMockExam: false,
              allowOffline: false,
              isFree: false,
              sortOrder: 0,
              contentVersion: 1,
              totalCount: 20,
              accessibleCount: 20,
              lockedCount: 0,
              locked: false,
              attemptsUsed: 0,
              bestScorePercent: null,
              inProgressAttemptId: null,
            ),
          ],
        );
      },
    );
    app.container.read(routerProvider).go('/subjects/p');
    await tester.pumpAndSettle();

    // Unit 1 is complete: collapsed into the green row; unit 2 is the current unit.
    expect(find.text('وحدة واحدة مكتملة'), findsOneWidget);
    expect(find.text('السرعة'), findsNothing);
    expect(find.text('الوحدة 2'), findsOneWidget);
    expect(find.text('3 دروس + اختبار الوحدة'), findsOneWidget);
    expect(find.bySemanticsLabel('التيار، مكتمل'), findsOneWidget);
    expect(find.bySemanticsLabel('المقاومة، الحالي'), findsOneWidget);
    expect(find.bySemanticsLabel('الدارات، لم يبدأ'), findsOneWidget);
    expect(find.bySemanticsLabel('اختبار الكهرباء، اختبار الوحدة'), findsOneWidget);
    expect(find.text('ابدأ هنا'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A tap opens the node's card; its action continues the lesson's questions.
    await tester.tap(find.bySemanticsLabel('المقاومة، الحالي'));
    await tester.pumpAndSettle();
    expect(find.text('12 سؤالاً · أنجزت \u206630%\u2069'), findsOneWidget);
    expect(find.text('عرض الدرس بالتفصيل'), findsOneWidget);
    await tester.tap(find.text('تابع الدرس'));
    await tester.pumpAndSettle();
    expect(
      app.container.read(routerProvider).routeInformationProvider.value.uri.toString(),
      '/subjects/p/questions?lessonId=l3',
    );
  });

  testWidgets('learning path: an upcoming lesson stays tappable and opens its lesson page', (tester) async {
    phoneSize(tester, const Size(360, 2000));
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => SubjectOutline(
          subject: subject('p', 'الفيزياء'),
          units: const [
            UnitWithLessons(
              id: 'u1',
              subjectId: 'p',
              code: 'u1',
              titleAr: 'الحركة',
              sortOrder: 0,
              lessons: [
                Lesson(id: 'l1', subjectId: 'p', unitId: 'u1', code: 'l1', titleAr: 'السرعة', sortOrder: 0),
                Lesson(id: 'l2', subjectId: 'p', unitId: 'u1', code: 'l2', titleAr: 'التسارع', sortOrder: 1),
              ],
            ),
          ],
          lessons: const [],
          access: noAccess,
          questionCount: noQuestions,
          deckCount: noQuestions,
          quizCount: noQuestions,
          tracks: const [],
        ),
      ),
      arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
    );
    app.container.read(routerProvider).go('/subjects/p');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('السرعة، الحالي'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('التسارع، لم يبدأ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض الدرس بالتفصيل'));
    await tester.pumpAndSettle();
    expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, '/subjects/p/lessons/l2');
  });

  testWidgets('subjects tab and subject page fit 360 wide with large text in dark mode', (tester) async {
    phoneSize(tester, const Size(360, 780));
    tester.platformDispatcher.textScaleFactorTestValue = 1.16;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer(
          (_) async => [
            catalogSubject('p', 'الفيزياء', description: 'الميكانيك والكهرباء والضوء والفيزياء الحديثة'),
            catalogSubject('a', 'اللغة العربية', description: 'نحو وأدب وبلاغة'),
          ],
        );
        when(() => c.outline('p')).thenAnswer(
          (_) async => SubjectOutline(
            subject: subject('p', 'الفيزياء'),
            units: const [
              UnitWithLessons(
                id: 'u1',
                subjectId: 'p',
                code: 'u1',
                titleAr: 'الميكانيك والحركة في بعدين',
                sortOrder: 0,
                lessons: [Lesson(id: 'l1', subjectId: 'p', unitId: 'u1', code: 'l1', titleAr: 'السرعة', sortOrder: 0)],
              ),
            ],
            lessons: const [],
            access: noAccess,
            questionCount: const ContentCount(total: 480, free: 40),
            deckCount: const ContentCount(total: 12, free: 2),
            quizCount: const ContentCount(total: 12, free: 1),
            tracks: const [],
          ),
        );
      },
      arrangeLearning: (l) => when(() => l.quizzes(any())).thenAnswer((_) async => const []),
    );
    await openSubjectsTab(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('الفيزياء'));
    await tester.pumpAndSettle();
    expect(find.text('480 · 40 مجاني'), findsOneWidget);
    expect(find.text('إدخال كود التفعيل'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(app.container.read(routerProvider).routeInformationProvider.value.uri.path, '/subjects/p');
  });
}
