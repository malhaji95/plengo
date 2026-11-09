import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/auth/auth_widgets.dart';
import 'package:plengo/features/update/force_update_screen.dart';

import 'helpers.dart';

Future<void> typeInto(WidgetTester tester, String label, String text) async {
  // Labels sit above the fields (V-Login): find the field inside the labelled AuthField.
  final field = find.descendant(of: find.widgetWithText(AuthField, label), matching: find.byType(TextField));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
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
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(10 * 2.0 * 1.16, 0.001));
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

  testWidgets('V-Account: grouped rows, red sign-out card, and the delete sheet keeps the warning', (tester) async {
    final semantics = tester.ensureSemantics();
    final app = await pumpApp(tester, signedInAs: testMe);
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    expect(find.text('student@example.com'), findsOneWidget);
    expect(tester.widget<Text>(find.text('student@example.com')).textDirection, TextDirection.ltr);
    expect(find.bySemanticsLabel('تغيير الصورة الشخصية'), findsOneWidget);
    // The stage row shows the student's level.
    expect(find.text('البكالوريا'), findsOneWidget);
    for (final row in [
      'صلاحيات الوصول',
      'إدخال كود التفعيل',
      'الإشعارات والهدف اليومي',
      'المرحلة التعليمية',
      'المدرسون الذين أتابعهم',
      'الأجهزة المتصلة',
      'سياسة الخصوصية',
      'شروط الاستخدام',
      'تراخيص البرمجيات والخطوط',
      'تسجيل الخروج',
      'حذف الحساب',
    ]) {
      await tester.scrollUntilVisible(find.text(row), 100);
      expect(find.text(row), findsOneWidget, reason: row);
    }
    await tester.tap(find.text('حذف الحساب'));
    await tester.pumpAndSettle();
    expect(find.text('حذف الحساب نهائياً'), findsOneWidget);
    expect(find.textContaining('لا يمكن التراجع عن هذه الخطوة.'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور للتأكيد'), findsOneWidget);
    semantics.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('entry and account screens fit 360 wide with large text (${dark ? 'dark' : 'light'})', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Starts signed out; the session is restored later straight onto /account so Home (another
      // screen group) is never built.
      Me? session;
      final app = await pumpApp(
        tester,
        arrange: (r) {
          when(() => r.restoreSession()).thenAnswer((_) async => session);
          when(() => r.sessions()).thenAnswer(
            (_) async => [
              SessionSummary(
                id: 's1',
                platform: SessionPlatform.android,
                appVersion: '1.0.0',
                userAgent: null,
                createdAt: DateTime.utc(2026, 9, 20, 9),
                lastSeenAt: DateTime.utc(2026, 9, 27, 9),
                current: true,
              ),
              SessionSummary(
                id: 's2',
                platform: SessionPlatform.web,
                appVersion: '1.0.0',
                userAgent: null,
                createdAt: DateTime.utc(2026, 9, 20, 9),
                lastSeenAt: DateTime.utc(2026, 9, 27, 9),
                current: false,
              ),
            ],
          );
        },
      );
      final appearance = app.container.read(appearanceProvider.notifier);
      await appearance.setFontStep(2);
      await appearance.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final router = app.container.read(routerProvider);
      for (final path in [
        Routes.login,
        Routes.register,
        Uri(path: Routes.verifyEmail, queryParameters: {'email': 'a.very.long.address@example.com'}).toString(),
        Routes.forgotPassword,
        Routes.resetPassword,
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      // The college box of the register form.
      router.go(Routes.register);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('الجامعة'));
      await tester.tap(find.text('الجامعة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      session = testMe;
      app.container.invalidate(authControllerProvider);
      router.go(Routes.account);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, Routes.account);
      for (final path in [Routes.account, Routes.redeem, Routes.myAccess, Routes.placement, Routes.sessions]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.scrollUntilVisible(find.text('إنهاء'), 100);
      expect(find.text('هذا الجهاز'), findsOneWidget);
    });
  }
}
