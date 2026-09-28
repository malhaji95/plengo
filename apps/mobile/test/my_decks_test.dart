import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/db/app_database.dart';
import 'package:plengo/core/srs/srs_key.dart';
import 'package:plengo/features/flashcards/study_screen.dart';

import 'flashcards_test.dart' show card, deck;
import 'helpers.dart';

RemoteConfig configWith({bool studentDecks = true, bool contentReports = true}) => RemoteConfig(
  minSupportedVersion: const MinSupportedVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  latestVersion: const LatestVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  features: Features(
    teacherFollowing: true,
    randomPractice: true,
    studentDecks: studentDecks,
    streaks: true,
    contentReports: contentReports,
  ),
  srsDefaults: const SrsDefaults(newCardsPerDay: 20, maxReviewsPerDay: 200),
  support: const Support(email: '', whatsapp: ''),
  storeUrls: const StoreUrls(android: '', ios: ''),
  privacyPolicyUrl: '',
  termsUrl: '',
);

Future<void> createDeckNamed(WidgetTester tester, String name) async {
  await tester.tap(find.text('مجموعة جديدة').last);
  await tester.pumpAndSettle();
  await tester.enterText(fieldByKey('deck-name'), name);
  await tester.pump();
  await tester.tap(find.text('حفظ'));
  await tester.pumpAndSettle();
}

/// Lets the sync debounce (2 s) fire so no timer outlives the test.
Future<void> flushSync(WidgetTester tester) => tester.pump(const Duration(seconds: 3));

void main() {
  final t0 = DateTime.utc(2026, 9, 28, 9).millisecondsSinceEpoch;

  testWidgets('creates a deck and a text card offline, then studies it (§13.9)', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe, clock: () => t0);
    app.container.read(routerProvider).go(Routes.review);
    await tester.pumpAndSettle();
    await tester.tap(find.text('بطاقاتي'));
    await tester.pumpAndSettle();
    expect(find.text('أنشئ مجموعتك الأولى وأضف إليها بطاقاتك الخاصة'), findsOneWidget);

    await createDeckNamed(tester, 'مصطلحات الكيمياء');
    expect(find.text('مصطلحات الكيمياء'), findsOneWidget);
    await tester.tap(find.text('مصطلحات الكيمياء'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'مراجعة')).onPressed, isNull);

    await tester.tap(find.text('بطاقة جديدة'));
    await tester.pumpAndSettle();
    // Both faces need text or an image.
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'حفظ البطاقة')).onPressed, isNull);
    await tester.enterText(fieldByKey('front-text'), 'الذرة');
    await tester.enterText(fieldByKey('back-text'), 'أصغر وحدة في العنصر');
    await tester.pump();
    await tester.tap(find.text('حفظ البطاقة'));
    await tester.pumpAndSettle();
    expect(find.text('الذرة'), findsOneWidget);
    expect(find.text('بطاقة واحدة'), findsOneWidget);

    // The card is stored locally, dirty until the server accepts it.
    final row = (await app.db.select(app.db.localCards).get()).single;
    expect(row.dirty, isTrue);

    await tester.tap(find.text('مراجعة'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyScreen), findsOneWidget);
    expect(find.text('الذرة'), findsOneWidget);
    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    expect(find.text('أصغر وحدة في العنصر'), findsOneWidget);
    await tester.tap(find.text('جيد'));
    await tester.pumpAndSettle();
    final logs = await app.db.select(app.db.srsReviewLogs).get();
    expect(logs.single.flashcardId, SrsKey.userCard(row.id));
    // Studying needed no server call for the deck itself.
    verifyNever(() => app.flashcards.deckCards(any()));
    await flushSync(tester);
  });

  testWidgets('adds a picked image to a card face', (tester) async {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 4]);
    final app = await pumpApp(tester, signedInAs: testMe, pickedImage: jpeg);
    await app.db
        .into(app.db.localDecks)
        .insert(LocalDecksCompanion.insert(id: 'd1', name: 'صوري', sortOrder: 0, createdAt: t0, updatedAt: t0));
    app.container.read(routerProvider).go('${Routes.myDecks}/d1/cards/new');
    await tester.pumpAndSettle();
    await tester.tap(fieldByKey('front-image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('من المعرض'));
    await tester.pumpAndSettle();
    expect(find.text('إزالة الصورة'), findsOneWidget);
    await tester.enterText(fieldByKey('back-text'), 'ما هذا؟');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'حفظ'));
    await tester.pumpAndSettle();
    final row = (await app.db.select(app.db.localCards).get()).single;
    expect(row.frontLocalImage, jpeg);
    expect(row.frontText, isNull);
    expect(row.frontMediaId, isNull); // uploaded by the sync
    await flushSync(tester);
  });

  testWidgets('refuses a new deck beyond the quota of 50 (§12.8)', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe);
    for (var i = 0; i < 50; i++) {
      await app.db
          .into(app.db.localDecks)
          .insert(LocalDecksCompanion.insert(id: 'd$i', name: 'م$i', sortOrder: i, createdAt: t0, updatedAt: t0));
    }
    app.container.read(routerProvider).go(Routes.myDecks);
    await tester.pumpAndSettle();
    await tester.tap(find.text('مجموعة جديدة'));
    await tester.pumpAndSettle();
    expect(find.text('وصلت إلى الحد الأقصى: 50 مجموعة'), findsOneWidget);
    expect(find.byKey(const Key('deck-name')), findsNothing);
  });

  testWidgets('"أضف إلى بطاقاتي" adds an official card to a new deck', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) => when(
        () => f.deckCards('d1'),
      ).thenAnswer((_) async => DeckCards(deck: deck(), cards: [card(0), card(1)], urlsExpireAt: '')),
    );
    app.container.read(routerProvider).go('${Routes.decks}/d1/browse');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('أضف إلى بطاقاتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مجموعة جديدة'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldByKey('deck-name'), 'للمراجعة');
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('أُضيفت البطاقة إلى مجموعتك'), findsOneWidget);
    final row = (await app.db.select(app.db.localCards).get()).single;
    expect(row.kind, 'official_ref');
    expect(row.officialFlashcardId, card(0).id);
    expect(row.frontImageJson, contains(card(0).front.mediaId));
    await flushSync(tester);
  });

  testWidgets('a locked official reference is kept but left out of study', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe, clock: () => t0);
    await app.db
        .into(app.db.localDecks)
        .insert(LocalDecksCompanion.insert(id: 'd1', name: 'مجموعتي', sortOrder: 0, createdAt: t0, updatedAt: t0));
    await app.db
        .into(app.db.localCards)
        .insert(
          LocalCardsCompanion.insert(
            id: 'c1',
            deckId: 'd1',
            kind: 'official_ref',
            officialFlashcardId: const Value('f1'),
            locked: const Value(true),
            sortOrder: 0,
            createdAt: t0,
            updatedAt: t0,
            dirty: const Value(false),
          ),
        );
    app.container.read(routerProvider).go('${Routes.myDecks}/d1');
    await tester.pumpAndSettle();
    expect(find.text('غير متاحة على حسابك حالياً'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'مراجعة')).onPressed, isNull);
  });

  testWidgets('reports a problem on an official card (§21)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeFlashcards: (f) => when(
        () => f.deckCards('d1'),
      ).thenAnswer((_) async => DeckCards(deck: deck(), cards: [card(0)], urlsExpireAt: '')),
    );
    when(() => app.reports.create(any(), any(), any(), any())).thenAnswer(
      (_) async => const Report(
        id: 'r1',
        itemType: ReportItemType.flashcard,
        itemId: 'c0',
        reason: ReportReason.imageProblem,
        note: null,
        status: ReportStatus.open,
        createdAt: '',
        resolvedAt: null,
      ),
    );
    app.container.read(routerProvider).go('${Routes.decks}/d1/browse');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إبلاغ عن مشكلة'));
    await tester.pumpAndSettle();
    // Cards have no answer to be wrong.
    expect(find.text('الإجابة خاطئة'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إرسال البلاغ')).onPressed, isNull);
    await tester.tap(find.text('مشكلة في الصورة'));
    await tester.enterText(fieldByKey('report-note'), '  الصورة مقلوبة ');
    await tester.pump();
    await tester.tap(find.text('إرسال البلاغ'));
    await tester.pumpAndSettle();
    verify(
      () => app.reports.create(ReportItemType.flashcard, card(0).id, ReportReason.imageProblem, 'الصورة مقلوبة'),
    ).called(1);
    expect(find.text('شكراً، وصلنا بلاغك وسنراجعه'), findsOneWidget);
  });

  testWidgets('remote flags hide student decks and reports', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      config: configWith(studentDecks: false, contentReports: false),
      arrangeFlashcards: (f) {
        when(
          () => f.deckCards('d1'),
        ).thenAnswer((_) async => DeckCards(deck: deck(), cards: [card(0)], urlsExpireAt: ''));
        when(
          () => f.due(subjectId: any(named: 'subjectId')),
        ).thenAnswer((_) async => const DueCards(cards: [], userCards: [], urlsExpireAt: ''));
      },
    );
    app.container.read(routerProvider).go('${Routes.decks}/d1/browse');
    await tester.pumpAndSettle();
    expect(find.byTooltip('أضف إلى بطاقاتي'), findsNothing);
    expect(find.byTooltip('إبلاغ عن مشكلة'), findsNothing);
    app.container.read(routerProvider).go(Routes.review);
    await tester.pumpAndSettle();
    expect(find.text('بطاقاتي'), findsNothing);
  });
}
