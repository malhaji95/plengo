import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/flashcards/deck_screen.dart';
import 'package:plengo/features/loyalty/loyalty_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

/// نقاطي (V3_PLAN §10): the screen, redeeming (deck unlock, custom, not enough points), the Home chip
/// and the drawer row, all hidden while loyalty is off.
void main() {
  setUpAll(registerFallbacks);

  LoyaltyReward reward(
    String id,
    String title, {
    int cost = 100,
    LoyaltyRewardKind kind = LoyaltyRewardKind.unlockDeck,
    bool affordable = true,
    bool owned = false,
  }) => LoyaltyReward(
    id: id,
    titleAr: title,
    description: 'وصف المكافأة',
    costPoints: cost,
    kind: kind,
    deckId: kind == LoyaltyRewardKind.unlockDeck ? 'dk-$id' : null,
    deckTitleAr: kind == LoyaltyRewardKind.unlockDeck ? 'مجموعة قوانين الفيزياء' : null,
    deckSubjectId: kind == LoyaltyRewardKind.unlockDeck ? 'p' : null,
    alreadyOwned: owned,
    affordable: affordable,
    sortOrder: 0,
  );

  final rewards = [
    reward('r1', 'افتح مجموعة الفيزياء'),
    reward('r2', 'دفتر بلينغو', kind: LoyaltyRewardKind.custom, cost: 80),
    reward('r3', 'افتح مجموعة الكيمياء', cost: 500, affordable: false),
  ];

  LoyaltyRedemption redemption(String id, LoyaltyRedemptionStatus status, {String? deckId}) => LoyaltyRedemption(
    id: id,
    rewardId: 'r2',
    titleAr: 'دفتر بلينغو',
    kind: deckId == null ? LoyaltyRewardKind.custom : LoyaltyRewardKind.unlockDeck,
    costPoints: 80,
    deckId: deckId,
    status: status,
    note: null,
    createdAt: '2026-11-10T08:00:00Z',
    handledAt: null,
  );

  void arrange(MockLoyaltyRepository l, {bool enabled = true}) {
    when(() => l.summary()).thenAnswer((_) async => loyaltySummary(enabled: enabled));
    when(() => l.rewards()).thenAnswer((_) async => LoyaltyRewardList(balance: 120, items: rewards));
    when(() => l.history()).thenAnswer(
      (_) async => const [
        LoyaltyLedgerEntry(
          id: 'h1',
          delta: 12,
          reason: LoyaltyReason.review,
          refId: null,
          day: '2026-11-18',
          note: null,
          createdAt: '2026-11-18T09:00:00Z',
        ),
        LoyaltyLedgerEntry(
          id: 'h2',
          delta: -80,
          reason: LoyaltyReason.redemption,
          refId: 'x',
          day: '2026-11-10',
          note: null,
          createdAt: '2026-11-10T08:00:00Z',
        ),
      ],
    );
    when(() => l.redemptions()).thenAnswer((_) async => [redemption('x', LoyaltyRedemptionStatus.pending)]);
  }

  Future<PumpedApp> open(WidgetTester tester, {bool enabled = true, Size size = const Size(390, 844)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpApp(
      tester,
      signedInAs: testMe,
      arrangeLoyalty: (l) => arrange(l, enabled: enabled),
    );
  }

  Future<void> goLoyalty(WidgetTester tester, PumpedApp app) async {
    app.container.read(routerProvider).push(Routes.loyalty).ignore();
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('the screen: balance, today toward the cap, how to earn, rewards, my requests, history', (tester) async {
    final app = await open(tester);
    await goLoyalty(tester, app);
    expect(find.byType(LoyaltyScreen), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('loyalty.balance'))).data, '120');
    expect(find.text('30 من 100'), findsOneWidget);
    expect(find.text('تبقّى لك 70 نقطة اليوم.'), findsOneWidget);
    expect(find.text('راجع بطاقة من بطاقاتك المستحقة'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('افتح مجموعة الفيزياء'), 200);
    expect(find.text('100 نقطة'), findsWidgets);
    await tester.scrollUntilVisible(find.text('تحتاج 380 نقطة إضافية'), 200);
    // Not affordable: the button is disabled.
    expect(tester.widget<PlengoButton>(find.byKey(const Key('loyalty.redeem.r3'))).onPressed, isNull);
    await tester.scrollUntilVisible(find.text('قيد المراجعة'), 200);
    await tester.scrollUntilVisible(find.text('مراجعة البطاقات'), 200);
    expect(find.text('+12'), findsOneWidget);
    expect(find.text('−80'), findsOneWidget);
  });

  testWidgets('redeeming a deck: confirm, the deck opens, the balance and lists refresh', (tester) async {
    final app = await open(tester);
    when(() => app.loyalty.redeem('r1')).thenAnswer((_) async {
      when(() => app.loyalty.summary()).thenAnswer((_) async => loyaltySummary(balance: 20));
      return LoyaltyRedeemResult(
        redemption: redemption('y', LoyaltyRedemptionStatus.fulfilled, deckId: 'dk-r1'),
        balance: 20,
      );
    });
    await goLoyalty(tester, app);
    await tapVisible(tester, find.byKey(const Key('loyalty.redeem.r1')));
    expect(find.text('استبدال 100 نقطة؟'), findsOneWidget);
    expect(find.text('«افتح مجموعة الفيزياء» مقابل 100 نقطة. يبقى لك 20 نقطة.'), findsOneWidget);
    await tester.tap(find.widgetWithText(PlengoButton, 'استبدال').last);
    await tester.pumpAndSettle();
    verify(() => app.loyalty.redeem('r1')).called(1);
    expect(find.text('تم فتح المجموعة!'), findsOneWidget);
    expect(find.text('أصبحت «مجموعة قوانين الفيزياء» متاحة لك.'), findsOneWidget);
    expect(find.text('رصيدك الآن: 20 نقطة'), findsOneWidget);
    verify(() => app.loyalty.summary()).called(greaterThan(1));
    verify(() => app.loyalty.rewards()).called(greaterThan(1));

    await tester.tap(find.byKey(const Key('loyalty.openDeck')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loyalty.success')), findsNothing);
    expect(tester.widget<DeckScreen>(find.byType(DeckScreen)).deckId, 'dk-r1');
  });

  testWidgets('a custom reward: «تم إرسال طلبك»', (tester) async {
    final app = await open(tester);
    when(() => app.loyalty.redeem('r2')).thenAnswer(
      (_) async => LoyaltyRedeemResult(redemption: redemption('z', LoyaltyRedemptionStatus.pending), balance: 40),
    );
    await goLoyalty(tester, app);
    await tapVisible(tester, find.byKey(const Key('loyalty.redeem.r2')));
    await tester.tap(find.widgetWithText(PlengoButton, 'استبدال').last);
    await tester.pumpAndSettle();
    expect(find.text('تم إرسال طلبك'), findsOneWidget);
    await tester.tap(find.text('حسناً'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loyalty.success')), findsNothing);
  });

  testWidgets('not enough points: the server message, no success sheet', (tester) async {
    final app = await open(tester);
    when(
      () => app.loyalty.redeem('r1'),
    ).thenThrow(const ApiException('INSUFFICIENT_POINTS', 'نقاطك غير كافية لهذه المكافأة', statusCode: 409));
    await goLoyalty(tester, app);
    await tapVisible(tester, find.byKey(const Key('loyalty.redeem.r1')));
    await tester.tap(find.widgetWithText(PlengoButton, 'استبدال').last);
    await tester.pumpAndSettle();
    expect(find.text('نقاطك غير كافية لهذه المكافأة'), findsOneWidget);
    expect(find.byKey(const Key('loyalty.success')), findsNothing);
    // The rewards are fetched again to show the server's balance.
    verify(() => app.loyalty.rewards()).called(greaterThan(1));
  });

  testWidgets('cancelling the confirm sheet redeems nothing', (tester) async {
    final app = await open(tester);
    await goLoyalty(tester, app);
    await tapVisible(tester, find.byKey(const Key('loyalty.redeem.r1')));
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    verifyNever(() => app.loyalty.redeem(any()));
  });

  testWidgets('Home: the ★ chip shows the balance and opens نقاطي', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('home.points')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('home.points')), matching: find.text('120')), findsOneWidget);
    expect(find.bySemanticsLabel('نقاطي: 120 نقطة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home.points')));
    await tester.pumpAndSettle();
    expect(find.byType(LoyaltyScreen), findsOneWidget);
  });

  testWidgets('loyalty off: no Home chip, no drawer row, and the screen says it is unavailable', (tester) async {
    final app = await open(tester, enabled: false);
    expect(find.byKey(const Key('home.points')), findsNothing);
    await tester.tap(find.byKey(const Key('shell.menu')).first);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('shell.drawer')), matching: find.text('نقاطي')), findsNothing);
    Navigator.of(tester.element(find.byKey(const Key('shell.drawer')))).pop();
    await tester.pumpAndSettle();
    await goLoyalty(tester, app);
    expect(find.byKey(const Key('loyalty.disabled')), findsOneWidget);
    verifyNever(() => app.loyalty.rewards());
  });

  testWidgets('drawer: «نقاطي» under the divider, before المحفوظات; it opens the screen', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('shell.menu')).first);
    await tester.pumpAndSettle();
    final drawer = find.byKey(const Key('shell.drawer'));
    Finder row(String l) => find.descendant(of: drawer, matching: find.text(l));
    expect(row('نقاطي'), findsOneWidget);
    final account = tester.getCenter(row('حسابي')).dy;
    final points = tester.getCenter(row('نقاطي')).dy;
    final saved = tester.getCenter(row('المحفوظات')).dy;
    final divider = tester.getCenter(find.descendant(of: drawer, matching: find.byType(Divider))).dy;
    expect(account < divider && divider < points && points < saved, isTrue);
    await tester.tap(row('نقاطي'));
    await tester.pumpAndSettle();
    expect(find.byType(LoyaltyScreen), findsOneWidget);
  });

  testWidgets('no overflow at 360×800 with large text, light and dark', (tester) async {
    final app = await open(tester, size: const Size(360, 800));
    final appearance = app.container.read(appearanceProvider.notifier);
    await appearance.setFontStep(2);
    for (final dark in [false, true]) {
      await appearance.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home ${dark ? 'dark' : 'light'}');
    }
    await goLoyalty(tester, app);
    for (final dark in [false, true]) {
      await appearance.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'loyalty ${dark ? 'dark' : 'light'} scroll $i');
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
    }
  });
}
