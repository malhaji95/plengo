import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/srs/scheduler.dart';
import 'package:plengo/features/flashcards/flashcard_providers.dart';
import 'package:plengo/features/flashcards/study_screen.dart';
import 'package:plengo/features/home/streak_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

CardImage image(String id) =>
    CardImage(mediaId: id, cacheKey: '$id:1', fullUrl: 'https://x/$id', thumbUrl: 'https://x/$id', width: 3, height: 2);

StudentCard card(int i) =>
    StudentCard(id: 'c$i', deckId: 'd1', sortOrder: i, contentVersion: 1, front: image('f$i'), back: image('b$i'));

StudentDeck deck({bool locked = false}) => StudentDeck(
  id: 'd1',
  subjectId: 'p',
  teacherTrackId: null,
  unitId: null,
  lessonId: null,
  titleAr: 'قوانين نيوتن',
  description: null,
  coverUrl: null,
  cardCount: 3,
  isFree: true,
  locked: locked,
  contentVersion: 1,
  sortOrder: 0,
);

final t0 = DateTime.utc(2026, 9, 27, 9).millisecondsSinceEpoch;

/// Lets the debounced background sync run (it is mocked) so no timer outlives the test.
Future<void> flushSync(WidgetTester tester) => tester.pump(const Duration(seconds: 3));

/// The live counts at the top of a study session (جديدة · تعلّم · مراجعة).
void expectCounts({required int fresh, required int learning, required int review}) {
  String count(String bucket) => (find.byKey(Key('count-$bucket')).evaluate().single.widget as Text).data!;
  expect([count('fresh'), count('learning'), count('review')], ['$fresh', '$learning', '$review']);
}

SrsCardState reviewState(String id, {int? dueAt}) => SrsCardState(
  state: SrsCardStateState.review,
  step: 0,
  dueAt: DateTime.fromMillisecondsSinceEpoch(dueAt ?? t0 - 1000, isUtc: true),
  intervalDays: 3,
  ease: 2.5,
  reps: 2,
  lapses: 0,
  lastReviewedAt: DateTime.fromMillisecondsSinceEpoch(t0 - 3 * 86400000, isUtc: true),
  flashcardId: id,
  userCardId: null,
  updatedAt: '2026-09-24T09:00:00Z',
);

StudentDeck deckWith(String id, {int cardCount = 3, bool locked = false, bool isFree = false}) => StudentDeck(
  id: id,
  subjectId: 'p',
  teacherTrackId: null,
  unitId: null,
  lessonId: null,
  titleAr: 'مجموعة $id',
  description: null,
  coverUrl: null,
  cardCount: cardCount,
  isFree: isFree,
  locked: locked,
  contentVersion: 1,
  sortOrder: 0,
);

void main() {
  late int now;
  setUp(() => now = t0);

  Future<PumpedApp> openStudy(WidgetTester tester, {int cards = 3}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      clock: () => now,
      arrangeFlashcards: (f) {
        when(() => f.deck('d1')).thenAnswer((_) async => deck());
        when(() => f.deckCards('d1')).thenAnswer(
          (_) async => DeckCards(deck: deck(), cards: [for (var i = 0; i < cards; i++) card(i)], urlsExpireAt: ''),
        );
      },
    );
    app.container.read(routerProvider).go('/decks/d1/study');
    await tester.pumpAndSettle();
    return app;
  }

  testWidgets('study: flip shows predicted intervals; Good schedules and logs locally', (tester) async {
    final app = await openStudy(tester);
    expect(find.byType(StudyScreen), findsOneWidget);
    expectCounts(fresh: 3, learning: 0, review: 0);
    expect(find.text('img:f0'), findsOneWidget);

    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    expect(find.text('img:b0'), findsOneWidget);
    expect(find.text('< 1 د'), findsOneWidget);
    expect(find.text('10 د'), findsOneWidget);
    expect(find.text('4 أيام'), findsOneWidget);

    await tester.tap(find.text('جيد'));
    await tester.pumpAndSettle();
    expect(find.text('img:f1'), findsOneWidget);
    expectCounts(fresh: 2, learning: 1, review: 0);

    final db = app.db;
    final logs = await db.select(db.srsReviewLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.rating, 'good');
    expect(logs.single.synced, isFalse);
    final state = await (db.select(db.srsCardStates)..where((t) => t.flashcardId.equals('c0'))).getSingle();
    expect(state.state, 'learning');
    await flushSync(tester);
  });

  testWidgets('study: undo restores the card and marks the log undone (§13.3)', (tester) async {
    final app = await openStudy(tester);
    for (final _ in [0, 1]) {
      await tester.tap(find.text('اقلب البطاقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سهل'));
      await tester.pumpAndSettle();
    }
    expect(find.text('img:f2'), findsOneWidget);
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(find.text('img:f1'), findsOneWidget);
    expectCounts(fresh: 2, learning: 0, review: 0);

    final db = app.db;
    final logs = await (db.select(db.srsReviewLogs)..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)])).get();
    expect(logs.map((l) => l.undone), [false, true]);
    final c1 = await (db.select(db.srsCardStates)..where((t) => t.flashcardId.equals('c1'))).getSingle();
    expect(c1.state, 'new');

    // Undo again, then nothing is left to undo.
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(find.text('img:f0'), findsOneWidget);
    expect(tester.widget<PlengoButton>(find.widgetWithText(PlengoButton, 'تراجع')).onPressed, isNull);
    await flushSync(tester);
  });

  testWidgets('study: keyboard shortcuts (Space, 1/2/3, Z) and the daily new-card limit', (tester) async {
    await openStudy(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('img:b0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3); // Easy
    await tester.pumpAndSettle();
    expect(find.text('img:f1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.pumpAndSettle();
    expect(find.text('img:f0'), findsOneWidget);

    // Graduate every card: learning cards come back after 10 minutes, then the day is done.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
    }
    expect(find.text('أنهيت مراجعة اليوم'), findsOneWidget);
    await flushSync(tester);
  });

  testWidgets('browse: previous / next and RTL arrow keys, no scheduling', (tester) async {
    final app = await openStudy(tester);
    app.container.read(routerProvider).go('/decks/d1/browse');
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('img:f1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // next in Arabic reading direction
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    expect(find.text('img:b1'), findsOneWidget);
    final db = app.db;
    expect(await db.select(db.srsReviewLogs).get(), isEmpty);
  });

  testWidgets('a locked deck offers no study modes', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) => when(() => f.deck('d1')).thenAnswer((_) async => deck(locked: true)),
    );
    app.container.read(routerProvider).go('/decks/d1');
    await tester.pumpAndSettle();
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);
    expect(find.text('مراجعة'), findsNothing);
  });

  testWidgets('review tab: every due card across subjects, filterable by subject (§13.2)', (tester) async {
    DueCard due(int i, String subjectId, String name) => DueCard(
      card: card(i),
      deckTitleAr: 'مجموعة',
      subjectId: subjectId,
      subjectNameAr: name,
      state: reviewState('c$i'),
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) => when(() => f.due(subjectId: any(named: 'subjectId'))).thenAnswer(
        (_) async => DueCards(
          cards: [due(0, 'p', 'الفيزياء'), due(1, 'p', 'الفيزياء'), due(2, 'm', 'الرياضيات')],
          userCards: const [],
          urlsExpireAt: '',
        ),
      ),
    );
    app.container.read(routerProvider).go(Routes.review);
    await tester.pumpAndSettle();
    expect(find.text('مراجعة الأخطاء'), findsOneWidget);
    expect(find.text('إحصائياتي'), findsOneWidget);
    expect(find.text('تدريب عشوائي'), findsOneWidget);
    expect(find.text('كل البطاقات المستحقة'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('بطاقات · حوالي دقيقة'), findsOneWidget);
    expect(find.text('مراجعة 3'), findsOneWidget);
    expect(find.text('جديدة 0'), findsOneWidget);
    await tester.tap(find.text('الرياضيات'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('مراجعة 1'), findsOneWidget);
  });

  testWidgets('review tab: nothing due shows when the next card is due', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      clock: () => now,
      arrangeFlashcards: (f) => when(
        () => f.due(subjectId: any(named: 'subjectId')),
      ).thenAnswer((_) async => const DueCards(cards: [], userCards: [], urlsExpireAt: '')),
    );
    // A card reviewed on this device, due tomorrow at 07:30 Damascus time.
    final tomorrow = DateTime.utc(2026, 9, 28, 4, 30).millisecondsSinceEpoch;
    await app.container
        .read(srsStoreProvider)
        .putState(
          'c9',
          CardState(
            state: CardStateName.review,
            step: 0,
            dueAt: tomorrow,
            intervalDays: 1,
            ease: 2.5,
            reps: 1,
            lapses: 0,
            lastReviewedAt: t0,
          ),
        );
    app.container.read(routerProvider).go(Routes.review);
    await tester.pumpAndSettle();
    expect(find.text('لا توجد بطاقات مستحقة الآن'), findsOneWidget);
    expect(find.text('البطاقة التالية: غداً 07:30'), findsOneWidget);
  });

  testWidgets('deck list: per-deck due chips from one due call, locked decks, and the summary', (tester) async {
    DueCard due(int i, String deckId) => DueCard(
      card: StudentCard(
        id: 'c$i',
        deckId: deckId,
        sortOrder: i,
        contentVersion: 1,
        front: image('f$i'),
        back: image('b$i'),
      ),
      deckTitleAr: 'مجموعة',
      subjectId: 'p',
      subjectNameAr: 'الفيزياء',
      state: reviewState('c$i'),
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) {
        when(() => f.decks(any())).thenAnswer(
          (_) async => [
            deckWith('d1', cardCount: 42, isFree: true),
            deckWith('d2', cardCount: 2),
            deckWith('d3', cardCount: 11, locked: true),
          ],
        );
        when(
          () => f.due(subjectId: 'p'),
        ).thenAnswer((_) async => DueCards(cards: [due(0, 'd1'), due(1, 'd1')], userCards: const [], urlsExpireAt: ''));
      },
    );
    app.container.read(routerProvider).go('/subjects/p/decks');
    await tester.pumpAndSettle();
    expect(find.text('كل البطاقات المستحقة: 2'), findsOneWidget);
    expect(find.text('ابدأ المراجعة'), findsOneWidget);
    expect(find.text('2 مستحقة'), findsOneWidget);
    expect(find.text('لا شيء مستحق'), findsOneWidget);
    expect(find.text('مقفلة'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('3 مجموعات'), findsOneWidget);
    // One call for the whole list, grouped by deck.
    verify(() => app.flashcards.due(subjectId: 'p')).called(1);
  });

  testWidgets('deck page: due today from the local queue, buckets and minutes (DECISIONS #9)', (tester) async {
    final app = await openStudy(tester, cards: 16);
    // One card already in learning, due now.
    await app.container
        .read(srsStoreProvider)
        .putState(
          'c0',
          CardState(
            state: CardStateName.learning,
            step: 1,
            dueAt: t0 - 60000,
            intervalDays: 0,
            ease: 2.5,
            reps: 1,
            lapses: 0,
            lastReviewedAt: t0 - 600000,
          ),
        );
    app.container.read(routerProvider).go('/decks/d1');
    await tester.pumpAndSettle();
    expect(find.text('مستحقة اليوم: 16'), findsOneWidget);
    // 16 × 8 s = 128 s → 3 minutes.
    expect(find.text('حوالي 3 دقائق'), findsOneWidget);
    expect(find.text('جديدة 15'), findsOneWidget);
    expect(find.text('قيد التعلم 1'), findsOneWidget);
    expect(find.text('مراجعة 0'), findsOneWidget);
    expect(find.text('مراجعة'), findsOneWidget);
    expect(find.text('تصفح'), findsOneWidget);
  });

  testWidgets('deck page: nothing due shows the next card', (tester) async {
    final app = await openStudy(tester, cards: 1);
    await app.container
        .read(srsStoreProvider)
        .putState(
          'c0',
          CardState(
            state: CardStateName.review,
            step: 0,
            dueAt: DateTime.utc(2026, 9, 28, 16).millisecondsSinceEpoch,
            intervalDays: 1,
            ease: 2.5,
            reps: 1,
            lapses: 0,
            lastReviewedAt: t0,
          ),
        );
    app.container.read(routerProvider).go('/decks/d1');
    await tester.pumpAndSettle();
    expect(find.text('مستحقة اليوم: 0'), findsOneWidget);
    expect(find.text('البطاقة التالية: غداً 19:00'), findsOneWidget);
  });

  testWidgets('study: the done screen sums the ratings and goes home through the streak moment', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      clock: () => now,
      arrangeHome: (h) => when(() => h.home()).thenAnswer(
        (_) async =>
            testHome(today: const Today(dueCards: 0, goal: 20, done: 20, goalMet: true, streak: 4, week: noWeek)),
      ),
      arrangeFlashcards: (f) {
        when(() => f.deck('d1')).thenAnswer((_) async => deck());
        when(
          () => f.deckCards('d1'),
        ).thenAnswer((_) async => DeckCards(deck: deck(), cards: [card(0)], urlsExpireAt: ''));
      },
    );
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    app.container.read(routerProvider).go('/decks/d1/study');
    await tester.pumpAndSettle();
    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سهل'));
    await tester.pumpAndSettle();
    expect(find.text('أنهيت مراجعة اليوم'), findsOneWidget);
    expect(find.text('سهل 1'), findsOneWidget);
    expect(find.text('مرة أخرى 0'), findsOneWidget);
    expect(find.textContaining('البطاقة التالية: '), findsOneWidget);
    await tester.tap(find.text('العودة إلى الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byType(StreakScreen), findsOneWidget);
    expect(await app.db.getValue('streak.moment_day'), isNotNull);
    await flushSync(tester);
  });

  testWidgets('study: the undo button appears only after the first rating', (tester) async {
    await openStudy(tester);
    final undo = find.ancestor(of: find.text('تراجع'), matching: find.byType(Visibility));
    expect(tester.widget<Visibility>(undo).visible, isFalse);
    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    expect(find.text('مرة أخرى'), findsOneWidget);
    await tester.tap(find.text('مرة أخرى'));
    await tester.pumpAndSettle();
    expect(tester.widget<Visibility>(undo).visible, isTrue);
    expectCounts(fresh: 2, learning: 1, review: 0);
    await flushSync(tester);
  });

  for (final dark in [false, true]) {
    testWidgets('360 wide, large text${dark ? ', dark' : ''}: the flashcard screens lay out without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      DueCard due(int i) => DueCard(
        card: card(i),
        deckTitleAr: 'مجموعة',
        subjectId: 'p',
        subjectNameAr: 'الفيزياء',
        state: reviewState('c$i'),
      );
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        clock: () => now,
        arrangeFlashcards: (f) {
          when(() => f.decks(any())).thenAnswer(
            (_) async => [deckWith('d1', cardCount: 42, isFree: true), deckWith('d3', cardCount: 11, locked: true)],
          );
          when(() => f.deck('d1')).thenAnswer((_) async => deck());
          when(
            () => f.deckCards('d1'),
          ).thenAnswer((_) async => DeckCards(deck: deck(), cards: [card(0), card(1)], urlsExpireAt: ''));
          when(
            () => f.due(subjectId: any(named: 'subjectId')),
          ).thenAnswer((_) async => DueCards(cards: [due(0), due(1)], userCards: const [], urlsExpireAt: ''));
        },
      );
      final appearance = app.container.read(appearanceProvider.notifier);
      await appearance.setFontStep(2);
      if (dark) await appearance.setThemeMode(ThemeMode.dark);
      final router = app.container.read(routerProvider);
      for (final path in [Routes.review, '/subjects/p/decks', '/decks/d1', '/decks/d1/browse', Routes.myDecks]) {
        router.go(path);
        await tester.pumpAndSettle();
      }
      router.go('/decks/d1/study');
      await tester.pumpAndSettle();
      await tester.tap(find.text('اقلب البطاقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جيد'));
      await tester.pumpAndSettle();
      expect(find.text('تراجع'), findsOneWidget);
      // Nothing above threw a RenderFlex overflow.
      expect(tester.takeException(), isNull);
      await flushSync(tester);
    });
  }
}
