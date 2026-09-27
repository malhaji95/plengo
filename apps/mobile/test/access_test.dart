import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/access/my_access_screen.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/subjects/subject_screen.dart';

import 'helpers.dart';

const physicsScope = AccessScope(
  scopeType: AccessScopeScopeType.subject,
  subjectId: 'p',
  teacherTrackId: null,
  subjectNameAr: 'الفيزياء',
  trackTitleAr: null,
  teacherNameAr: null,
  educationLevelId: 'l12',
);

const trackScope = AccessScope(
  scopeType: AccessScopeScopeType.teacherTrack,
  subjectId: 'p',
  teacherTrackId: 'tr1',
  subjectNameAr: 'الفيزياء',
  trackTitleAr: 'أ. أحمد — فيزياء بكالوريا',
  teacherNameAr: 'أ. أحمد',
  educationLevelId: 'l12',
);

MyEntitlement entitlement(String id, AccessScope scope, MyEntitlementState state, {String? expiresAt}) => MyEntitlement(
  id: id,
  scope: scope,
  source: MyEntitlementSource.coupon,
  startsAt: '2026-09-01T10:00:00.000Z',
  expiresAt: expiresAt,
  isPermanent: expiresAt == null,
  state: state,
);

SubjectOutline outline(ScopeAccess access) => SubjectOutline(
  subject: subject('p', 'الفيزياء'),
  units: const [],
  lessons: const [],
  tracks: const [],
  access: access,
  questionCount: noQuestions,
);

Future<void> openSubject(dynamic app, WidgetTester tester) async {
  app.container.read(routerProvider).go('/subjects/p');
  await tester.pumpAndSettle();
}

void main() {
  group('coupon code input (§9.3)', () {
    test('keeps only alphabet characters, uppercases and maps Arabic/Persian digits', () {
      expect(CouponCodeFormatter.normalize('abcd-٢٣٤٥ xy'), 'ABCD2345XY');
      expect(CouponCodeFormatter.normalize('ab۲۳01OIL'), 'AB23');
      expect(CouponCodeFormatter.normalize('ABCD2345XYZZZ'), 'ABCD2345XY');
    });

    test('inserts dashes as XXXX-XXXX-XX', () {
      String typed(String s) =>
          CouponCodeFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s)).text;
      expect(typed('abc'), 'ABC');
      expect(typed('abcd2'), 'ABCD-2');
      expect(typed('abcd2345x'), 'ABCD-2345-X');
      expect(typed('abcd2345xy'), 'ABCD-2345-XY');
    });
  });

  testWidgets('a locked subject offers the code screen, and redeeming unlocks it (COUPON_REDEMPTION=true)', (
    tester,
  ) async {
    var unlocked = false;
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => outline(
          unlocked
              ? const ScopeAccess(
                  hasAccess: true,
                  reason: ScopeAccessReason.entitlement,
                  isPermanent: true,
                  entitlementExpiresAt: null,
                  promotionTitleAr: null,
                  promotionEndsAt: null,
                )
              : noAccess,
        ),
      ),
      arrangeAccess: (a) => when(() => a.redeem(any())).thenAnswer((_) async {
        unlocked = true;
        return RedeemResult(entitlement: entitlement('e1', physicsScope, MyEntitlementState.active), upgraded: false);
      }),
    );
    await openSubject(app, tester);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);

    await tester.tap(find.text('إدخال كود التفعيل'));
    await tester.pumpAndSettle();
    expect(find.byType(RedeemScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('coupon-code')), 'abcd2345xy');
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const Key('coupon-code')));
    expect(field.controller!.text, 'ABCD-2345-XY');
    expect(field.textDirection, TextDirection.ltr);

    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();
    verify(() => app.access.redeem('ABCD-2345-XY')).called(1);
    expect(find.text('تم التفعيل بنجاح'), findsOneWidget);
    expect(find.text('وصول دائم'), findsOneWidget);

    await tester.tap(find.text('الذهاب إلى المحتوى'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectScreen), findsOneWidget);
    expect(find.text('لديك وصول دائم إلى هذا المحتوى'), findsOneWidget);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsNothing);
  });

  testWidgets('shows the server message when a code fails', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeAccess: (a) => when(
        () => a.redeem(any()),
      ).thenThrow(const ApiException('COUPON_ALREADY_USED', 'تم استخدام هذا الكود مسبقاً', statusCode: 400)),
    );
    app.container.read(routerProvider).go(Routes.redeem);
    await tester.pumpAndSettle();
    // The button stays disabled until the code is complete.
    await tester.enterText(find.byKey(const Key('coupon-code')), 'ABCD234');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('coupon-code')), 'ABCD2345XY');
    await tester.pump();
    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();
    expect(find.text('تم استخدام هذا الكود مسبقاً'), findsOneWidget);
  });

  testWidgets('without COUPON_REDEMPTION the lock has no button and no redeem route (§8.7, §37.5)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      couponRedemption: false,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => outline(noAccess)),
    );
    await openSubject(app, tester);
    expect(find.text('هذا المحتوى غير متاح على حسابك'), findsOneWidget);
    expect(find.text('إدخال كود التفعيل'), findsNothing);

    app.container.read(routerProvider).go(Routes.redeem);
    await tester.pumpAndSettle();
    expect(find.byType(RedeemScreen), findsNothing);

    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    expect(find.text('صلاحيات الوصول'), findsOneWidget);
    expect(find.text('إدخال كود التفعيل'), findsNothing);
  });

  testWidgets('a running promotion opens the subject for everyone', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
        (_) async => outline(
          const ScopeAccess(
            hasAccess: true,
            reason: ScopeAccessReason.promotion,
            isPermanent: false,
            entitlementExpiresAt: null,
            promotionTitleAr: 'أسبوع مجاني',
            promotionEndsAt: '2026-10-01T20:59:59.000Z',
          ),
        ),
      ),
    );
    await openSubject(app, tester);
    // 20:59:59Z is 23:59:59 in Damascus: still 1 October there.
    expect(find.text('متاح مجاناً ضمن «أسبوع مجاني» حتى 2026/10/1'), findsOneWidget);
  });

  testWidgets('My access lists active entitlements first with their state', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeAccess: (a) => when(() => a.myEntitlements()).thenAnswer(
        (_) async => [
          entitlement('e1', physicsScope, MyEntitlementState.active),
          entitlement('e2', trackScope, MyEntitlementState.expired, expiresAt: '2026-06-30T20:59:59.000Z'),
        ],
      ),
    );
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    await tester.tap(find.text('صلاحيات الوصول'));
    await tester.pumpAndSettle();
    expect(find.byType(MyAccessScreen), findsOneWidget);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.text('أ. أحمد — فيزياء بكالوريا'), findsOneWidget);
    expect(find.text('فعّال'), findsOneWidget);
    expect(find.text('منتهي'), findsOneWidget);
    expect(find.textContaining('حتى 2026/6/30'), findsOneWidget);
    expect(find.text('إدخال كود التفعيل'), findsOneWidget);
  });
}
