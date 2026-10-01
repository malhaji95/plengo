import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/update/force_update_screen.dart';

import 'helpers.dart';

Future<void> typeInto(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
}

RemoteConfig config({String android = ''}) => RemoteConfig(
  minSupportedVersion: const MinSupportedVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  latestVersion: const LatestVersion(android: '1.0.0', ios: '1.0.0', web: '1.0.0'),
  features: const Features(
    teacherFollowing: true,
    randomPractice: true,
    studentDecks: true,
    streaks: true,
    contentReports: true,
  ),
  srsDefaults: const SrsDefaults(newCardsPerDay: 20, maxReviewsPerDay: 200),
  support: const Support(email: '', whatsapp: ''),
  storeUrls: StoreUrls(android: android, ios: ''),
  privacyPolicyUrl: '',
  termsUrl: '',
);

void main() {
  testWidgets('password reset by email OTP: request a code, then set a new password (§11.1)', (tester) async {
    final app = await pumpApp(
      tester,
      arrange: (r) {
        when(() => r.requestPasswordReset(any())).thenAnswer((_) async {});
        when(
          () => r.resetPassword(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenAnswer((_) async {});
      },
    );
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    await typeInto(tester, 'البريد الإلكتروني', 'Student@Example.com ');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();
    verify(() => app.repo.requestPasswordReset('student@example.com')).called(1);

    await typeInto(tester, 'رمز التحقق', '123456');
    await typeInto(tester, 'كلمة المرور الجديدة', 'new-password-123');
    await typeInto(tester, 'تأكيد كلمة المرور', 'new-password-123');
    await tester.ensureVisible(find.text('حفظ كلمة المرور'));
    await tester.tap(find.text('حفظ كلمة المرور'));
    await tester.pumpAndSettle();
    verify(
      () => app.repo.resetPassword(email: 'student@example.com', otp: '123456', newPassword: 'new-password-123'),
    ).called(1);
    expect(find.text('تم تغيير كلمة المرور، سجّل الدخول بكلمة المرور الجديدة'), findsOneWidget);
    expect(app.container.read(routerProvider).state.uri.path, Routes.login);
  });

  testWidgets('sessions: lists devices and ends another one (§11.2)', (tester) async {
    SessionSummary session(String id, {bool current = false}) => SessionSummary(
      id: id,
      platform: current ? SessionPlatform.android : SessionPlatform.web,
      appVersion: '1.0.0',
      userAgent: null,
      createdAt: DateTime.utc(2026, 9, 20, 9),
      lastSeenAt: DateTime.utc(2026, 9, 27, 9),
      current: current,
    );
    var remaining = [session('s1', current: true), session('s2')];
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrange: (r) {
        when(() => r.sessions()).thenAnswer((_) async => remaining);
        when(() => r.revokeSession('s2')).thenAnswer((_) async {
          remaining = [session('s1', current: true)];
        });
      },
    );
    app.container.read(routerProvider).go(Routes.sessions);
    await tester.pumpAndSettle();
    expect(find.text('هذا الجهاز'), findsOneWidget);
    await tester.tap(find.text('إنهاء'));
    await tester.pumpAndSettle();
    if (find.text('إنهاء').evaluate().isNotEmpty && find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('إنهاء').last);
      await tester.pumpAndSettle();
    }
    verify(() => app.repo.revokeSession('s2')).called(1);
    expect(find.text('إنهاء'), findsNothing);
  });

  testWidgets('dark mode and font size persist, and the size multiplies the phone text size (§25)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await pumpApp(tester, signedInAs: testMe);
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    await tester.tap(find.text('داكن'));
    await tester.tap(find.text('كبير'));
    await tester.pumpAndSettle();
    expect(await app.db.getValue('settings.theme_mode'), 'dark');
    expect(await app.db.getValue('settings.font_step'), '2');
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    final context = tester.element(find.text('حسابي').first);
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(10 * 2.0 * 1.15, 0.001));
  });

  testWidgets('force update: a store button on Android (§10.2)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      config: config(android: 'https://play.example/plengo'),
    );
    app.container.read(updateRequiredProvider.notifier).require();
    await tester.pumpAndSettle();
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.text('يرجى تحديث التطبيق'), findsOneWidget);
    expect(find.text('تحديث من المتجر'), findsOneWidget);
  });

  testWidgets('force update without a store link still blocks the app', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe, config: config());
    app.container.read(updateRequiredProvider.notifier).require();
    await tester.pumpAndSettle();
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.text('تحديث من المتجر'), findsNothing);
  });
}
