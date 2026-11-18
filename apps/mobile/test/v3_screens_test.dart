import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/app/theme.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/content/study_card.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/srs/scheduler.dart';
import 'package:plengo/core/srs/srs_store.dart';
import 'package:plengo/features/access/access_banner.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/bookmarks/saved_tab.dart';
import 'package:plengo/features/flashcards/card_face.dart';
import 'package:plengo/features/flashcards/hard_cards.dart';
import 'package:plengo/features/home/home_tab.dart';
import 'package:plengo/features/home/next_lesson_carousel.dart';
import 'package:plengo/features/my_subjects/my_subjects_providers.dart';
import 'package:plengo/features/my_subjects/my_subjects_screen.dart';
import 'package:plengo/features/practice/practice_screen.dart';
import 'package:plengo/features/splash/splash_screen.dart';
import 'package:plengo/features/subjects/learning_path.dart';
import 'package:plengo/features/subjects/locked_lessons.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'access_test.dart' show entitlement, physicsScope;
import 'helpers.dart';
import 'home_test.dart' show banner, location;

/// Plengo v3 phase A (docs/redesign/V3_PLAN.md §1–§4, §6, §8): splash, the Home carousels, the
/// hard cards, موادي, the subject page's stations and shortcuts, and long cards.
void main() {
  setUpAll(registerFallbacks);

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  void reduceMotion(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Lesson lesson(String id, String title, {String subjectId = 'p', String? unitId = 'u1', num order = 0}) =>
      Lesson(id: id, subjectId: subjectId, unitId: unitId, code: id, titleAr: title, sortOrder: order);

  LessonProgress lessonProgress(String id, int percent) => LessonProgress(
    questionsAttempted: 0,
    questionsCorrect: 0,
    questionsTotal: 0,
    quizzesCompleted: 0,
    quizzesTotal: 0,
    flashcardsStudied: 0,
    flashcardsTotal: 0,
    completionPercent: percent,
    lessonId: id,
  );

  ScopeProgress progressOf(String subjectId, int percent, List<LessonProgress> lessons) => ScopeProgress(
    questionsAttempted: 0,
    questionsCorrect: 0,
    questionsTotal: 0,
    quizzesCompleted: 0,
    quizzesTotal: 0,
    flashcardsStudied: 0,
    flashcardsTotal: 0,
    completionPercent: percent,
    subjectId: subjectId,
    teacherTrackId: null,
    lastActivityAt: null,
    units: const [],
    lessons: lessons,
  );

  SubjectOutline outlineOf(
    String id,
    String name, {
    List<UnitWithLessons> units = const [],
    List<Lesson> lessons = const [],
    ScopeAccess access = permanentAccess,
  }) => SubjectOutline(
    subject: subject(id, name),
    units: units,
    lessons: lessons,
    tracks: const [],
    access: access,
    questionCount: const ContentCount(total: 20, free: 5),
    deckCount: const ContentCount(total: 3, free: 1),
    quizCount: noQuestions,
  );

  UnitWithLessons unitOf(String id, String title, List<Lesson> lessons) => UnitWithLessons(
    id: id,
    subjectId: lessons.first.subjectId,
    code: id,
    titleAr: title,
    sortOrder: 0,
    lessons: lessons,
  );

  const mathScope = AccessScope(
    scopeType: AccessScopeScopeType.subject,
    subjectId: 'm',
    teacherTrackId: null,
    subjectNameAr: 'الرياضيات',
    trackTitleAr: null,
    teacherNameAr: null,
    educationLevelId: 'l12',
  );

  /// Physics (السرعة done, التسارع next) and maths (الاشتقاق next) in موادي.
  final physics = outlineOf(
    'p',
    'الفيزياء',
    units: [
      unitOf('u1', 'الحركة', [lesson('l1', 'السرعة'), lesson('l2', 'التسارع', order: 1)]),
    ],
  );
  final maths = outlineOf('m', 'الرياضيات', lessons: [lesson('l3', 'الاشتقاق', subjectId: 'm', unitId: null)]);

  Future<PumpedApp> pumpMine(
    WidgetTester tester, {
    List<MyEntitlement>? access,
    List<HomeBanner> banners = const [],
    int due = 12,
  }) => pumpApp(
    tester,
    signedInAs: testMe,
    arrangeHome: (h) => when(() => h.home()).thenAnswer(
      (_) async => testHome(
        banners: banners,
        today: Today(dueCards: due, goal: 20, done: 8, goalMet: false, streak: 4, week: noWeek),
        myAccess:
            access ??
            [
              entitlement('e1', physicsScope, MyEntitlementState.active),
              entitlement('e2', mathScope, MyEntitlementState.active),
            ],
        freeSubjects: const [FreeSubject(subjectId: 'c', nameAr: 'الكيمياء', freeCount: 14, coverUrl: null)],
      ),
    ),
    arrangeCatalog: (c) {
      when(() => c.outline('p')).thenAnswer((_) async => physics);
      when(() => c.outline('m')).thenAnswer((_) async => maths);
    },
    arrangeLearning: (l) {
      when(
        () => l.progress('p', teacherTrackId: null),
      ).thenAnswer((_) async => progressOf('p', 50, [lessonProgress('l1', 100), lessonProgress('l2', 20)]));
      when(() => l.quizzes(any())).thenAnswer((_) async => const []);
    },
  );

  group('splash (V3-Splash)', () {
    testWidgets('yellow, the blue wordmark and the slogan; the intro lasts at most 1.5 s', (tester) async {
      // A failed restore keeps the splash on screen (with «إعادة المحاولة»).
      await pumpApp(
        tester,
        arrange: (r) => when(() => r.restoreSession()).thenThrow(const ApiException('NETWORK', 'تعذّر الاتصال')),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text(splashSlogan), findsOneWidget);
      expect(find.text('صديقك لمراجعة أسرع وأمتع'), findsOneWidget);
      expect(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor, PlengoColors.yellow.base);
      final logo = tester.widget<Image>(find.descendant(of: find.byType(SplashMotion), matching: find.byType(Image)));
      expect((logo.image as AssetImage).assetName, 'assets/brand/wordmark-blue.png');
      expect(find.bySemanticsLabel('Plengo'), findsOneWidget);
      expect(SplashMotion.duration, lessThanOrEqualTo(const Duration(milliseconds: 1500)));
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    Future<double> opacityAfterFirstFrame(WidgetTester tester, {required bool reduced}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: app!,
          ),
          home: const Scaffold(body: Center(child: SplashMotion())),
        ),
      );
      final fade = tester.widget<FadeTransition>(
        find.descendant(of: find.byType(SplashMotion), matching: find.byType(FadeTransition)).first,
      );
      return fade.opacity.value;
    }

    testWidgets('the logo fades in; with reduced motion it is there at once', (tester) async {
      expect(await opacityAfterFirstFrame(tester, reduced: false), 0);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      expect(await opacityAfterFirstFrame(tester, reduced: true), 1);
    });
  });

  group('Home «راجع الدرس التالي:» carousel', () {
    test('the next lesson is the first below 100 % in path order; free subjects without access', () {
      expect(nextLesson(physics, progressOf('p', 50, [lessonProgress('l1', 100)]))?.id, 'l2');
      expect(nextLesson(physics, null)?.id, 'l1');
      expect(nextLesson(physics, progressOf('p', 100, [lessonProgress('l1', 100), lessonProgress('l2', 100)])), isNull);
      final mine = testHome(myAccess: [entitlement('e1', physicsScope, MyEntitlementState.active)]);
      expect(carouselSubjects(mine).map((s) => s.id), ['p']);
      final none = testHome(
        freeSubjects: const [FreeSubject(subjectId: 'c', nameAr: 'الكيمياء', freeCount: 3, coverUrl: null)],
      );
      expect(carouselSubjects(none).map((s) => s.id), ['c']);
    });

    testWidgets('one tile per subject; it moves every ~4 s, arrows and dots, ▶ opens the lesson', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpMine(tester);
      final carousel = find.byKey(const Key('home.nextLessons'));
      expect(carousel, findsOneWidget);
      expect(find.text('راجع الدرس التالي:'), findsOneWidget);
      expect(find.descendant(of: carousel, matching: find.text('التسارع')), findsOneWidget);
      expect(find.descendant(of: carousel, matching: find.text('الاشتقاق')), findsOneWidget);
      expect(find.bySemanticsLabel('الدرس 1 من 2'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^التسارع، الفيزياء، 1 من 2')), findsOneWidget);
      // Only the latest Continue item: no older resume rows.
      expect(find.byType(ResumeTile), findsNothing);

      NextLessonCarouselState state() => tester.state(find.byType(NextLessonCarouselView));
      expect(state().autoAdvancing, isTrue);
      await tester.pump(NextLessonCarouselView.interval);
      await tester.pumpAndSettle();
      expect(state().page, 1);
      expect(find.bySemanticsLabel('الدرس 2 من 2'), findsOneWidget);

      // A finger on it pauses the motion.
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('home.nextLessons.pager'))));
      await tester.pump(NextLessonCarouselView.interval * 2);
      expect(state().page, 1);
      expect(state().autoAdvancing, isFalse);
      // Lifted without a tap (a tap on the centre tile would open its lesson).
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(state().autoAdvancing, isTrue);

      await tester.tap(find.byTooltip('الدرس التالي'));
      await tester.pumpAndSettle();
      expect(state().page, 0);

      await tester.tap(find.byKey(const Key('home.nextLessons.play')));
      await tester.pumpAndSettle();
      expect(location(app), '/subjects/p/lessons/l2');
    });

    testWidgets('with reduced motion it never moves by itself', (tester) async {
      reduceMotion(tester);
      useSize(tester, const Size(390, 2400));
      await pumpMine(tester);
      NextLessonCarouselState state() => tester.state(find.byType(NextLessonCarouselView));
      expect(state().autoAdvancing, isFalse);
      await tester.pump(NextLessonCarouselView.interval * 3);
      await tester.pumpAndSettle();
      expect(state().page, 0);
    });
  });

  group('Home banners', () {
    final banners = [
      banner('b1', 'عرض الصيف', BannerAction.none),
      banner('b2', 'جديد', BannerAction.none),
      banner('b3', 'خصم', BannerAction.none),
    ];

    testWidgets('rotate every ~5 s with dots, pause while touched, and swipe', (tester) async {
      useSize(tester, const Size(390, 2400));
      await pumpMine(tester, banners: banners);
      BannerSliderState state() => tester.state(find.byType(BannerSlider));
      expect(state().page, 0);
      expect(find.bySemanticsLabel('البانر 1 من 3'), findsOneWidget);
      await tester.pump(BannerSlider.interval);
      await tester.pumpAndSettle();
      expect(state().page, 1);
      expect(find.bySemanticsLabel('البانر 2 من 3'), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.text('banner:جديد')));
      await tester.pump(BannerSlider.interval * 2);
      expect(state().page, 1);
      await gesture.up();
      await tester.pumpAndSettle();

      // Swipe to the next banner (it lies to the left in RTL).
      await tester.fling(find.text('banner:جديد'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(state().page, 2);
    });

    testWidgets('no rotation with reduced motion', (tester) async {
      reduceMotion(tester);
      useSize(tester, const Size(390, 2400));
      await pumpMine(tester, banners: banners);
      BannerSliderState state() => tester.state(find.byType(BannerSlider));
      await tester.pump(BannerSlider.interval * 3);
      await tester.pumpAndSettle();
      expect(state().page, 0);
      expect(state().autoAdvancing, isFalse);
    });
  });

  group('hard cards (v3 §8)', () {
    CardState state({int lapses = 0, double ease = 2.5}) =>
        CardState.newCard(0).copyWith(state: CardStateName.review, lapses: lapses, ease: ease);

    test('two or more lapses or a low ease, official cards only', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = SrsStore(db);
      await store.putState('c1', state(lapses: 2, ease: 2.3));
      await store.putState('c2', state(lapses: 1, ease: 2.0));
      await store.putState('c3', state(lapses: 1, ease: 2.3));
      await store.putState('c4', state());
      await store.putState('u:mine', state(lapses: 4, ease: 1.3));
      expect(await store.hardCardIds(), {'c1', 'c2'});
    });

    Bookmark card(String id, String title, String subjectId) => Bookmark(
      id: 'b$id',
      itemType: BookmarkItemType.flashcard,
      itemId: id,
      createdAt: '2026-09-20T00:00:00Z',
      locked: false,
      available: true,
      group: null,
      titleAr: title,
      subjectId: subjectId,
      subjectNameAr: subjectId == 'p' ? 'الفيزياء' : 'الرياضيات',
      question: null,
      deck: null,
      card: null,
      userCard: null,
    );

    testWidgets('the saved cards mark hard ones «صعبة» and list them first; ?subjectId= narrows', (tester) async {
      useSize(tester, const Size(390, 1200));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeLearning: (l) => when(() => l.bookmarks()).thenAnswer(
          (_) async => BookmarkList(
            items: [card('c9', 'بطاقة سهلة', 'p'), card('c1', 'بطاقة صعبة', 'p'), card('c5', 'بطاقة رياضيات', 'm')],
            nextCursor: null,
            urlsExpireAt: '',
          ),
        ),
      );
      await SrsStore(app.db).putState('c1', state(lapses: 3, ease: 1.9));
      // The study controller does this after each rating.
      app.container.invalidate(hardCardsProvider);
      app.container.read(routerProvider).go('${Routes.saved}?filter=cards&subjectId=p');
      await tester.pumpAndSettle();

      expect(find.byType(SavedTab), findsOneWidget);
      expect(find.text('صعبة'), findsOneWidget);
      expect(find.text('بطاقة رياضيات'), findsNothing);
      expect(tester.getTopLeft(find.text('بطاقة صعبة')).dy, lessThan(tester.getTopLeft(find.text('بطاقة سهلة')).dy));
      expect(find.text('الفيزياء'), findsWidgets);

      await tester.tap(find.byKey(const Key('saved.allSubjects')));
      await tester.pumpAndSettle();
      expect(find.text('بطاقة رياضيات'), findsOneWidget);
    });

    testWidgets('Home counts them in «مراجعة البطاقات الصعبة»', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpMine(tester);
      expect(find.text('مراجعة البطاقات الصعبة'), findsOneWidget);
      expect(find.text('البطاقات التي تجدها صعبة والمحفوظة'), findsOneWidget);
      await SrsStore(app.db).putState('c1', state(lapses: 2));
      app.container.invalidate(hardCardsProvider);
      await tester.pumpAndSettle();
      expect(find.text('1 من البطاقات تحتاج تركيزاً'), findsOneWidget);
    });
  });

  group('موادي', () {
    testWidgets('each subject: completion, the current lesson and its four ways in', (tester) async {
      useSize(tester, const Size(390, 1600));
      final app = await pumpMine(tester);
      final router = app.container.read(routerProvider);
      router.go(Routes.mySubjects);
      await tester.pumpAndSettle();
      expect(find.byType(MySubjectsScreen), findsOneWidget);
      final physicsCard = find.byKey(const Key('mySubject.p'));
      expect(physicsCard, findsOneWidget);
      expect(find.byKey(const Key('mySubject.m')), findsOneWidget);
      expect(find.descendant(of: physicsCard, matching: find.text('الدرس الحالي: التسارع')), findsOneWidget);
      expect(find.descendant(of: physicsCard, matching: find.bySemanticsLabel(RegExp('مكتمل'))), findsWidgets);
      expect(find.text('مراجعة البطاقات المستحقة (12)'), findsOneWidget);

      Future<void> tapIn(String label) async {
        final target = find.descendant(of: physicsCard, matching: find.text(label));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('mySubject.continue.p')));
      await tester.pumpAndSettle();
      expect(location(app), '/subjects/p/lessons/l2');

      for (final (label, target) in [
        ('مراجعة البطاقات الصعبة', '/saved?filter=cards&subjectId=p'),
        ('بطاقاتي', '/subjects/p'),
        ('إحصائياتي', '/review/stats/subjects/p'),
      ]) {
        router.go(Routes.mySubjects);
        await tester.pumpAndSettle();
        await tapIn(label);
        expect(location(app), target, reason: label);
      }
    });

    testWidgets('nothing activated: an empty state and the free content', (tester) async {
      useSize(tester, const Size(390, 1200));
      final app = await pumpMine(tester, access: const []);
      app.container.read(routerProvider).go(Routes.mySubjects);
      await tester.pumpAndSettle();
      expect(find.text('لم تفعّل أي مادة بعد'), findsOneWidget);
      expect(find.text('الكيمياء'), findsOneWidget);
      await tester.tap(find.text('تصفّح المواد'));
      await tester.pumpAndSettle();
      expect(location(app), Routes.subjects);
    });
  });

  group('subject page (v3 §3)', () {
    StudentQuiz quizOn(String lessonId, {bool locked = false}) => StudentQuiz(
      id: 'qz-$lessonId',
      subjectId: 'p',
      teacherTrackId: null,
      unitId: 'u1',
      lessonId: lessonId,
      titleAr: 'اختبار',
      description: null,
      allowedModes: StudentQuizAllowedModes.both,
      timeLimitSeconds: null,
      passingScorePercent: null,
      maxAttempts: null,
      isMockExam: false,
      allowOffline: false,
      isFree: !locked,
      sortOrder: 0,
      contentVersion: 1,
      totalCount: 5,
      accessibleCount: locked ? 0 : 5,
      lockedCount: locked ? 5 : 0,
      locked: locked,
      attemptsUsed: 0,
      bestScorePercent: null,
      inProgressAttemptId: null,
    );

    final stations = outlineOf(
      'p',
      'الفيزياء',
      access: noAccess,
      units: [
        unitOf('u1', 'الحركة', [
          lesson('l1', 'السرعة'),
          lesson('l2', 'التسارع', order: 1),
          lesson('l3', 'القوة', order: 2),
          lesson('l4', 'الطاقة', order: 3),
        ]),
      ],
    );

    Future<PumpedApp> openStations(WidgetTester tester, {bool coupon = true}) async {
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        couponRedemption: coupon,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => stations),
        arrangeFlashcards: (f) => when(() => f.decks(any())).thenAnswer((_) async => const []),
        arrangeLearning: (l) {
          when(
            () => l.progress('p', teacherTrackId: null),
          ).thenAnswer((_) async => progressOf('p', 30, [lessonProgress('l1', 100), lessonProgress('l2', 40)]));
          // القوة has a free quiz; الطاقة only a locked one.
          when(() => l.quizzes(any())).thenAnswer((_) async => [quizOn('l3'), quizOn('l4', locked: true)]);
        },
      );
      app.container.read(routerProvider).go('/subjects/p');
      await tester.pumpAndSettle();
      return app;
    }

    test('locked lessons come from access, open quizzes/decks and progress', () {
      const loaded = AsyncData<List<StudentDeck>>([]);
      expect(
        lockedLessonIds(
          outline: stations,
          quizzes: AsyncData([quizOn('l3'), quizOn('l4', locked: true)]),
          decks: loaded,
          percents: {'l1': 100, 'l2': 0},
        ),
        {'l2', 'l4'},
      );
      expect(
        lockedLessonIds(
          outline: outlineOf('p', 'الفيزياء', units: stations.units),
          quizzes: const AsyncData([]),
          decks: loaded,
          percents: const {},
        ),
        isEmpty,
      );
      expect(
        lockedLessonIds(outline: stations, quizzes: const AsyncLoading(), decks: loaded, percents: const {}),
        isNull,
      );
      expect(stationState(percent: 100, locked: false), StationState.finished);
      expect(stationState(percent: 1, locked: false), StationState.started);
      expect(stationState(percent: 0, locked: false), StationState.open);
      expect(stationState(percent: 100, locked: true), StationState.locked);
    });

    testWidgets('stations: finished green, started blue, open outlined, locked grey with a lock', (tester) async {
      useSize(tester, const Size(390, 2000));
      await openStations(tester);
      // No locked box and no «completed units» row any more.
      expect(find.byType(LockedNotice), findsNothing);
      expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsNothing);
      expect(find.byKey(const Key('units.completed')), findsNothing);

      BoxDecoration node(String kind) =>
          tester.widget<Container>(find.byKey(Key('node.$kind'))).decoration! as BoxDecoration;
      expect(node('finished').color, PlengoColors.green.base);
      expect(node('started').color, PlengoColors.blue.base);
      expect(node('open').border, isNotNull);
      final locked = find.byKey(const Key('node.locked'));
      expect(locked, findsOneWidget);
      expect(find.descendant(of: locked, matching: find.byIcon(Icons.lock_rounded)), findsOneWidget);
      final grey = node('locked').color!;
      expect(grey.r, closeTo(grey.g, 0.03));
      expect(grey.g, closeTo(grey.b, 0.03));

      expect(find.bySemanticsLabel('السرعة، مكتمل'), findsOneWidget);
      expect(find.bySemanticsLabel('التسارع، الحالي'), findsOneWidget);
      expect(find.bySemanticsLabel('القوة، لم يبدأ'), findsOneWidget);
      expect(find.bySemanticsLabel('الطاقة، مقفل، يحتاج إلى تفعيل'), findsOneWidget);
      // The header art slot shows its doodles until the owner's PNG is bundled.
      expect(find.byKey(const Key('subject.art.placeholder')), findsOneWidget);
    });

    testWidgets('a locked station opens the activation sheet; the code leads to redeem', (tester) async {
      useSize(tester, const Size(390, 2000));
      await openStations(tester);
      await tester.tap(find.bySemanticsLabel('الطاقة، مقفل، يحتاج إلى تفعيل'));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const Key('lockedLesson.sheet'));
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('هذا المحتوى يحتاج إلى تفعيل')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('الطاقة')), findsOneWidget);
      await tester.tap(find.text('إدخال كود التفعيل'));
      await tester.pumpAndSettle();
      final redeem = find.byType(RedeemScreen);
      expect(redeem, findsOneWidget);
      // The code screen knows the subject the student came from.
      expect(redeemOriginOf(tester.element(redeem)).subjectId, 'p');
    });

    testWidgets('without COUPON_REDEMPTION the sheet has no code button; the lesson stays reachable', (tester) async {
      useSize(tester, const Size(390, 2000));
      final app = await openStations(tester, coupon: false);
      await tester.tap(find.bySemanticsLabel('الطاقة، مقفل، يحتاج إلى تفعيل'));
      await tester.pumpAndSettle();
      expect(find.text('هذا المحتوى غير متاح على حسابك'), findsOneWidget);
      expect(find.text('إدخال كود التفعيل'), findsNothing);
      await tester.tap(find.text('عرض الدرس'));
      await tester.pumpAndSettle();
      expect(location(app), '/subjects/p/lessons/l4');
    });

    testWidgets('the four shortcuts: تدريب, بطاقات بلينغو, راجع أخطاءك, بطاقاتي', (tester) async {
      useSize(tester, const Size(390, 2000));
      final app = await openStations(tester);
      final router = app.container.read(routerProvider);
      final row = find.byKey(const Key('subject.shortcuts'));
      for (final (label, target) in [
        ('تدريب', '/practice/p'),
        ('بطاقات بلينغو', '/plengo-cards?subjectId=p'),
        ('راجع أخطاءك', '/saved?filter=cards&subjectId=p'),
        ('بطاقاتي', '/make-cards/groups?subjectId=p'),
      ]) {
        router.go('/subjects/p');
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: row, matching: find.text(label)));
        await tester.pumpAndSettle();
        expect(location(app), target, reason: label);
      }
      // Practice for the subject still offers the random practice that already exists.
      router.go('/practice/p');
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSetupScreen), findsOneWidget);
      expect(find.text('تدريب عشوائي'), findsOneWidget);
    });
  });

  group('long cards (v3 §6)', () {
    Future<void> pumpCard(WidgetTester tester, {required int width, required int height}) async {
      useSize(tester, const Size(390, 700));
      var flipped = false;
      final card = StudyCard(
        key: 'c1',
        front: CardFaceView(
          image: CardImage(
            mediaId: 'f',
            cacheKey: 'f:1',
            fullUrl: 'https://x/f',
            thumbUrl: '',
            width: width,
            height: height,
          ),
        ),
        back: const CardFaceView(text: 'الوجه الخلفي'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cardImageBuilderProvider.overrideWithValue(
              (_, image) => Container(
                color: const Color(0xFF0074B4),
                alignment: Alignment.topCenter,
                child: const Text('أعلى البطاقة'),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Center(
                  child: FlashcardView(
                    card: card,
                    flipped: flipped,
                    onTap: () => setState(() => flipped = !flipped),
                    maxHeight: 500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('a long card keeps its width and scrolls inside the card; a tap still flips it', (tester) async {
      await pumpCard(tester, width: 300, height: 1500);
      final scroll = find.byKey(const Key('flashcard.longScroll'));
      expect(scroll, findsOneWidget);
      expect(tester.getSize(scroll).height, 500);
      expect(tester.getSize(find.byType(FlashcardView)).width, 390);
      final top = tester.getTopLeft(find.text('أعلى البطاقة')).dy;
      await tester.drag(scroll, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('أعلى البطاقة')).dy, lessThan(top));

      await tester.tap(scroll);
      await tester.pumpAndSettle();
      expect(find.text('الوجه الخلفي'), findsOneWidget);
    });

    testWidgets('a regular card is narrowed to fit, with no scrolling', (tester) async {
      await pumpCard(tester, width: 600, height: 800);
      expect(find.byKey(const Key('flashcard.longScroll')), findsNothing);
      expect(tester.getSize(find.byType(FlashcardView)).height, lessThanOrEqualTo(500));
    });
  });

  group('360 × 800, large text', () {
    for (final dark in [false, true]) {
      testWidgets('v3 screens lay out without overflow (${dark ? 'dark' : 'light'})', (tester) async {
        useSize(tester, const Size(360, 800));
        tester.platformDispatcher.textScaleFactorTestValue = 1.16;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final app = await pumpMine(
          tester,
          banners: [banner('b1', 'عرض الصيف', BannerAction.none), banner('b2', 'جديد', BannerAction.none)],
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeTab), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('راجع الدرس التالي:'),
          200,
          scrollable: find.descendant(of: find.byType(HomeTab), matching: find.byType(Scrollable)).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('shell.menu')).first);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('shell.drawer')), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byKey(const Key('shell.drawer')))).pop();
        await tester.pumpAndSettle();

        final router = app.container.read(routerProvider);
        for (final path in [Routes.mySubjects, Routes.practice, '/practice/p', Routes.plengoCards, Routes.makeCards]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        router.go('/subjects/p');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('subject.shortcuts')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
