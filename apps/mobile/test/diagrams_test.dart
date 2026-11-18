import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/diagrams/diagram_repository.dart';
import 'package:plengo/features/diagrams/diagram_results.dart';
import 'package:plengo/features/diagrams/diagram_session.dart';
import 'package:plengo/features/diagrams/diagrams_screen.dart';

import 'helpers.dart';

class MockDiagramRepository extends Mock implements DiagramRepository {}

/// رسمات العلوم (V3_PLAN §9): the setup and its request per mode, the session checked per diagram or
/// at the end, the results, the locked / empty / offline states and the layout.
void main() {
  setUpAll(() {
    registerFallbacks();
    registerFallbackValue((subjectId: '', teacherTrackId: null, unitId: null, lessonIds: null));
    registerFallbackValue(const DiagramPracticeRequest(subjectId: '', count: 1));
    registerFallbackValue(<int, String>{});
  });

  Lesson lesson(String id, String title, String? unitId) =>
      Lesson(id: id, subjectId: 'bio', unitId: unitId, code: id, titleAr: title, sortOrder: 0);

  final outline = SubjectOutline(
    subject: subject('bio', 'علم الأحياء'),
    units: [
      UnitWithLessons(
        id: 'u1',
        subjectId: 'bio',
        code: 'u1',
        titleAr: 'الوحدة الأولى: الخلية',
        sortOrder: 0,
        lessons: [lesson('l1', 'الخلية الحيوانية', 'u1'), lesson('l2', 'الخلية النباتية', 'u1')],
      ),
      UnitWithLessons(
        id: 'u2',
        subjectId: 'bio',
        code: 'u2',
        titleAr: 'الوحدة الثانية: الوراثة',
        sortOrder: 1,
        lessons: [lesson('l3', 'الصبغيات', 'u2')],
      ),
    ],
    lessons: [lesson('g1', 'مدخل إلى الأحياء', null)],
    tracks: const [],
    access: permanentAccess,
    questionCount: noQuestions,
    deckCount: noQuestions,
    quizCount: noQuestions,
  );

  PracticeDiagram diagram(String id, String title) => PracticeDiagram(
    id: id,
    subjectId: 'bio',
    unitId: 'u1',
    lessonId: 'l1',
    titleAr: title,
    image: CardImage(mediaId: 'm$id', cacheKey: 'k$id', fullUrl: 'https://cdn/$id.png', thumbUrl: '', width: 800, height: 600),
    labels: [
      PracticeDiagramLabel(id: '$id-b', number: 2, x: null, y: null),
      PracticeDiagramLabel(id: '$id-a', number: 1, x: 0.25, y: 0.4),
    ],
    contentVersion: 1,
  );

  final diagrams = [diagram('d1', 'الخلية الحيوانية'), diagram('d2', 'الخلية النباتية')];

  DiagramCheckResult result(String id, {required bool second}) => DiagramCheckResult(
    diagramId: id,
    correctCount: second ? 2 : 1,
    totalCount: 2,
    labels: [
      DiagramLabelResult(labelId: '$id-a', number: 1, answer: 'النواة', isCorrect: true, acceptedAnswers: const ['النواة']),
      DiagramLabelResult(
        labelId: '$id-b',
        number: 2,
        answer: second ? 'الغشاء الخلوي' : null,
        isCorrect: second,
        acceptedAnswers: const ['الغشاء الخلوي', 'الغشاء البلازمي'],
      ),
    ],
  );

  StudentDiagramList listOf({int accessible = 4, int locked = 0}) => StudentDiagramList(
    items: const [],
    totalCount: accessible + locked,
    accessibleCount: accessible,
    lockedCount: locked,
  );

  Future<(PumpedApp, MockDiagramRepository)> open(
    WidgetTester tester, {
    void Function(MockDiagramRepository repo)? arrange,
    String location = '${Routes.practiceDiagrams}?subjectId=bio',
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MockDiagramRepository();
    when(() => repo.list(any())).thenAnswer((_) async => listOf());
    when(() => repo.start(any())).thenAnswer(
      (_) async => DiagramPractice(diagrams: diagrams, availableCount: 4, lockedCount: 0, urlsExpireAt: ''),
    );
    when(() => repo.check(any(), any())).thenAnswer(
      (i) async => result(i.positionalArguments.first as String, second: i.positionalArguments.first == 'd2'),
    );
    arrange?.call(repo);
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer(
          (_) async => [catalogSubject('bio', 'علم الأحياء'), catalogSubject('chem', 'الكيمياء')],
        );
        when(() => c.outline('bio')).thenAnswer((_) async => outline);
      },
      extraOverrides: [diagramRepositoryProvider.overrideWithValue(repo)],
    );
    app.container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return (app, repo);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Scrolls the screen's list until [text] is built and visible.
  Future<Finder> seen(WidgetTester tester, Object textOrFinder) async {
    final f = textOrFinder is Finder ? textOrFinder : find.text(textOrFinder as String);
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    return f;
  }

  Future<void> exitSession(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('diagrams.exit')));
    await tester.pumpAndSettle();
    expect(find.text('الخروج من التدريب؟'), findsOneWidget);
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(find.byType(DiagramSession), findsNothing);
  }

  Map<String, Object?> lastStart(MockDiagramRepository repo) =>
      (verify(() => repo.start(captureAny())).captured.last as DiagramPracticeRequest).toJson();

  testWidgets('setup: the subject from the query, available counts, the stepper and the request per mode', (
    tester,
  ) async {
    final (_, repo) = await open(tester);
    expect(find.byType(DiagramsScreen), findsOneWidget);
    expect(find.byKey(const Key('diagrams.subjectName')), findsOneWidget);
    expect(find.text('الكيمياء'), findsOneWidget);
    for (final step in ['الاختيار', 'التدريبات', 'النتيجة']) {
      expect(find.text(step), findsOneWidget);
    }
    // Whole unit (the first by default): 4 available, the count starts at 4 (≤ 5) and steps 1…4.
    verify(() => repo.list((subjectId: 'bio', teacherTrackId: null, unitId: 'u1', lessonIds: null))).called(1);
    expect(find.text('4 رسمة متاحة'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('diagrams.count'))).data, '4');
    await tapKey(tester, 'diagrams.count.plus');
    expect(tester.widget<Text>(find.byKey(const Key('diagrams.count'))).data, '4');
    await tapKey(tester, 'diagrams.count.minus');
    await tapKey(tester, 'diagrams.count.minus');
    expect(tester.widget<Text>(find.byKey(const Key('diagrams.count'))).data, '2');
    await tapKey(tester, 'diagrams.start');
    expect(lastStart(repo), {'subjectId': 'bio', 'unitId': 'u1', 'count': 2});
    expect(find.byType(DiagramSession), findsOneWidget);
    await exitSession(tester);

    // Several lessons: nothing picked yet → no request, «ابدأ» disabled.
    await tapText(tester, 'عدة دروس');
    expect(find.text('اختر درساً واحداً على الأقل'), findsOneWidget);
    await tapKey(tester, 'diagrams.start');
    verifyNever(() => repo.start(any()));
    await tapKey(tester, 'diagrams.lesson.l2');
    await tapKey(tester, 'diagrams.lesson.l1');
    verify(() => repo.list((subjectId: 'bio', teacherTrackId: null, unitId: null, lessonIds: 'l1,l2'))).called(1);
    await tapKey(tester, 'diagrams.start');
    expect(lastStart(repo), {
      'subjectId': 'bio',
      'lessonIds': ['l1', 'l2'],
      'count': 2,
    });
    await exitSession(tester);

    // One lesson, from the second unit.
    await tapText(tester, 'درس واحد');
    await tapText(tester, 'الوحدة الأولى: الخلية');
    await tapText(tester, 'الوحدة الثانية: الوراثة');
    await tapText(tester, 'اختر الدرس');
    await tapText(tester, 'الصبغيات');
    await tapKey(tester, 'diagrams.start');
    expect(lastStart(repo), {
      'subjectId': 'bio',
      'lessonIds': ['l3'],
      'count': 2,
    });
  });

  testWidgets('session checked after each diagram: ✓ / ✗ with the accepted answer, then التالي', (tester) async {
    final (_, repo) = await open(tester);
    await tapKey(tester, 'diagrams.start');
    expect(find.text('رسمة 1 من 2'), findsOneWidget);
    expect(find.text('الخلية الحيوانية'), findsWidgets);
    // Fields in number order; the placed marker is drawn on the image.
    final y1 = tester.getCenter(find.byKey(const Key('diagrams.answer.1'))).dy;
    final y2 = tester.getCenter(find.byKey(const Key('diagrams.answer.2'))).dy;
    expect(y1, lessThan(y2));
    expect(find.text('img:md1'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('diagrams.answer.1')), ' النواة ');
    await tapText(tester, 'تحقق');
    final sent = verify(() => repo.check('d1', captureAny())).captured.single as Map<int, String>;
    expect(sent[1], ' النواة ');
    expect(sent[2], '');
    expect(await seen(tester, 'الإجابة الصحيحة للرقم 2: الغشاء الخلوي / الغشاء البلازمي'), findsOneWidget);
    expect(await seen(tester, '1 من 2 صحيحة'), findsOneWidget);
    expect(find.bySemanticsLabel('صحيحة'), findsOneWidget);
    expect(find.bySemanticsLabel('خاطئة'), findsOneWidget);

    await tapText(tester, 'التالي');
    expect(find.text('رسمة 2 من 2'), findsOneWidget);
    await tapText(tester, 'تحقق');
    verify(() => repo.check('d2', any())).called(1);
    expect(await seen(tester, 'أحسنت! 2 من 2 صحيحة'), findsOneWidget);
    await tapText(tester, 'عرض النتيجة');

    expect(find.text('تم إنهاء التدريب!'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
  });

  testWidgets('session checked at the end: no check until «إنهاء وتصحيح», then the results', (tester) async {
    final (_, repo) = await open(tester);
    await tapKey(tester, 'diagrams.check.end');
    await tapKey(tester, 'diagrams.start');
    expect(find.text('تحقق'), findsNothing);
    await tester.enterText(find.byKey(const Key('diagrams.answer.1')), 'النواة');
    await tapText(tester, 'التالي');
    verifyNever(() => repo.check(any(), any()));
    expect(find.text('رسمة 2 من 2'), findsOneWidget);
    await tapText(tester, 'إنهاء وتصحيح');
    verify(() => repo.check('d1', any())).called(1);
    verify(() => repo.check('d2', any())).called(1);

    // Results: score, correct answers, diagrams; each diagram expands to its labels.
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    await tester.tap(find.byKey(const Key('diagrams.result.d1')));
    await tester.pumpAndSettle();
    expect(await seen(tester, 'لم تكتب إجابة'), findsOneWidget);
    expect(await seen(tester, 'الإجابة الصحيحة: الغشاء الخلوي / الغشاء البلازمي'), findsOneWidget);

    // «إعادة التدريب»: the same diagrams again, without a new draw.
    await tapKey(tester, 'diagrams.retry');
    expect(find.byType(DiagramSession), findsOneWidget);
    expect(find.text('رسمة 1 من 2'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('diagrams.answer.1'))).controller!.text, isEmpty);
    verify(() => repo.start(any())).called(1);
    await tapText(tester, 'التالي');
    await tapText(tester, 'إنهاء وتصحيح');
    // «تدريب آخر»: back to the setup.
    await tapKey(tester, 'diagrams.another');
    expect(find.byKey(const Key('diagrams.start')), findsOneWidget);
  });

  test('score: correct labels over all labels, rounded', () {
    final s = diagramScore([result('d1', second: false), result('d2', second: true)]);
    expect((s.diagrams, s.correct, s.total, s.percent), (2, 3, 4, 75));
    expect(diagramScore(const []).percent, 0);
  });

  testWidgets('locked scope: a lock box with the code entry and «ابدأ» disabled', (tester) async {
    final (_, repo) = await open(
      tester,
      arrange: (r) => when(() => r.list(any())).thenAnswer((_) async => listOf(accessible: 0, locked: 3)),
    );
    expect(find.byKey(const Key('diagrams.locked')), findsOneWidget);
    expect(find.text('3 مقفلة'), findsOneWidget);
    expect(find.byKey(const Key('diagrams.count')), findsNothing);
    await tapKey(tester, 'diagrams.start');
    verifyNever(() => repo.start(any()));
    await tapText(tester, 'إدخال كود التفعيل');
    expect(find.byType(RedeemScreen), findsOneWidget);
  });

  testWidgets('empty scope: «لا توجد رسومات هنا بعد»', (tester) async {
    await open(tester, arrange: (r) => when(() => r.list(any())).thenAnswer((_) async => listOf(accessible: 0)));
    expect(find.byKey(const Key('diagrams.empty')), findsOneWidget);
    expect(find.byKey(const Key('diagrams.locked')), findsNothing);
  });

  testWidgets('offline: «تحتاج إلى اتصال بالإنترنت» with retry, for the counts and for the start', (tester) async {
    var offline = true;
    final (_, repo) = await open(
      tester,
      arrange: (r) => when(() => r.list(any())).thenAnswer(
        (_) async => offline ? throw const ApiException('NETWORK_ERROR', ApiException.networkMessage) : listOf(),
      ),
    );
    expect(find.text('تحتاج إلى اتصال بالإنترنت'), findsOneWidget);
    offline = false;
    await tapText(tester, 'إعادة المحاولة');
    expect(find.text('4 رسمة متاحة'), findsOneWidget);

    when(() => repo.start(any())).thenThrow(const ApiException('NETWORK_ERROR', ApiException.networkMessage));
    await tapKey(tester, 'diagrams.start');
    expect(find.text('تحتاج إلى اتصال بالإنترنت'), findsOneWidget);
    expect(find.byType(DiagramSession), findsNothing);
  });

  testWidgets('offline before the outline loads: a full error state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(
        () => c.outline('bio'),
      ).thenAnswer((_) async => throw const ApiException('NETWORK_ERROR', ApiException.networkMessage)),
    );
    app.container.read(routerProvider).go('${Routes.practiceDiagrams}?subjectId=bio');
    await tester.pumpAndSettle();
    expect(find.text('تحتاج إلى اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('no subject in the query: the first subject of the level; the pills switch subject', (tester) async {
    final (_, repo) = await open(tester, location: Routes.practiceDiagrams);
    expect(find.byKey(const Key('diagrams.subjectName')), findsOneWidget);
    verify(() => repo.list((subjectId: 'bio', teacherTrackId: null, unitId: 'u1', lessonIds: null))).called(1);
  });

  testWidgets('no overflow at 360×800 with large text, light and dark: setup, session, results', (tester) async {
    final (app, _) = await open(tester, size: const Size(360, 800));
    final appearance = app.container.read(appearanceProvider.notifier);
    await appearance.setFontStep(2);
    for (final dark in [false, true]) {
      await appearance.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'setup ${dark ? 'dark' : 'light'}');
      await tapKey(tester, 'diagrams.start');
      expect(tester.takeException(), isNull, reason: 'session ${dark ? 'dark' : 'light'}');
      await tapText(tester, 'تحقق');
      expect(tester.takeException(), isNull, reason: 'checked ${dark ? 'dark' : 'light'}');
      await tapText(tester, 'التالي');
      await tapText(tester, 'تحقق');
      await tapText(tester, 'عرض النتيجة');
      await tester.tap(await seen(tester, find.byKey(const Key('diagrams.result.d1'))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'results ${dark ? 'dark' : 'light'}');
      await tapKey(tester, 'diagrams.another');
    }
  });
}
