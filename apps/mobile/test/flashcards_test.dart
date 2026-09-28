import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/flashcards/study_screen.dart';

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
    expect(find.text('جديدة 3 · تعلّم 0 · مراجعة 0'), findsOneWidget);
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
    expect(find.text('جديدة 2 · تعلّم 1 · مراجعة 0'), findsOneWidget);

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
    expect(find.text('جديدة 2 · تعلّم 0 · مراجعة 0'), findsOneWidget);

    final db = app.db;
    final logs = await (db.select(db.srsReviewLogs)..orderBy([(t) => OrderingTerm.asc(t.reviewedAt)])).get();
    expect(logs.map((l) => l.undone), [false, true]);
    final c1 = await (db.select(db.srsCardStates)..where((t) => t.flashcardId.equals('c1'))).getSingle();
    expect(c1.state, 'new');

    // Undo again, then nothing is left to undo.
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(find.text('img:f0'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'تراجع')).onPressed, isNull);
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
    expect(find.text('أنهيت مراجعة اليوم 🎉'), findsOneWidget);
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
    SrsCardState state(String id) => SrsCardState(
      state: SrsCardStateState.review,
      step: 0,
      dueAt: DateTime.fromMillisecondsSinceEpoch(t0 - 1000, isUtc: true),
      intervalDays: 3,
      ease: 2.5,
      reps: 2,
      lapses: 0,
      lastReviewedAt: DateTime.fromMillisecondsSinceEpoch(t0 - 3 * 86400000, isUtc: true),
      flashcardId: id,
      userCardId: null,
      updatedAt: '2026-09-24T09:00:00Z',
    );
    DueCard due(int i, String subjectId, String name) =>
        DueCard(card: card(i), deckTitleAr: 'مجموعة', subjectId: subjectId, subjectNameAr: name, state: state('c$i'));
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
    expect(find.text('كل البطاقات المستحقة: 3 بطاقات'), findsOneWidget);
    await tester.tap(find.text('الرياضيات'));
    await tester.pumpAndSettle();
    expect(find.text('كل البطاقات المستحقة: بطاقة واحدة'), findsOneWidget);
  });
}
