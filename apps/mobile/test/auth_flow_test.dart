import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/features/auth/login_screen.dart';
import 'package:plengo/features/auth/verify_email_screen.dart';
import 'package:plengo/features/shell/home_shell.dart';

import 'helpers.dart';

void main() {
  testWidgets('signed-out users land on the Arabic RTL login screen', (tester) async {
    await pumpApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsWidgets);
    final direction = Directionality.of(tester.element(find.byType(LoginScreen)));
    expect(direction, TextDirection.rtl);
  });

  testWidgets('shows Arabic validation errors for an empty form', (tester) async {
    await pumpApp(tester);
    await tester.tap(fieldByKey('login.submit'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل البريد الإلكتروني'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور'), findsOneWidget);
  });

  testWidgets('shows the server message for wrong credentials', (tester) async {
    final app = await pumpApp(
      tester,
      arrange: (repo) => when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          appVersion: any(named: 'appVersion'),
        ),
      ).thenThrow(const ApiException('AUTH_INVALID_CREDENTIALS', 'بيانات الدخول غير صحيحة', statusCode: 401)),
    );
    await tester.enterText(fieldByKey('login.email'), 'Student@Example.com ');
    await tester.enterText(fieldByKey('login.password'), 'wrong-password');
    await tester.tap(fieldByKey('login.submit'));
    await tester.pumpAndSettle();
    expect(find.text('بيانات الدخول غير صحيحة'), findsOneWidget);
    verify(
      () => app.repo.login(email: 'student@example.com', password: 'wrong-password', appVersion: '1.0.0'),
    ).called(1);
  });

  testWidgets('successful login opens the five-tab home shell', (tester) async {
    await pumpApp(
      tester,
      arrange: (repo) => when(
        () => repo.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          appVersion: any(named: 'appVersion'),
        ),
      ).thenAnswer((_) async => testMe),
    );
    await tester.enterText(fieldByKey('login.email'), 'student@example.com');
    await tester.enterText(fieldByKey('login.password'), 'correct-horse');
    await tester.tap(fieldByKey('login.submit'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    for (final label in ['الرئيسية', 'المواد', 'المراجعة', 'المحفوظات', 'حسابي']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('an unverified account is sent to OTP verification with a fresh code', (tester) async {
    final app = await pumpApp(
      tester,
      arrange: (repo) {
        when(
          () => repo.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            appVersion: any(named: 'appVersion'),
          ),
        ).thenThrow(const ApiException('AUTH_EMAIL_NOT_VERIFIED', 'البريد الإلكتروني غير مُفعّل', statusCode: 403));
        when(() => repo.resendVerification(any())).thenAnswer((_) async {});
      },
    );
    await tester.enterText(fieldByKey('login.email'), 'new@example.com');
    await tester.enterText(fieldByKey('login.password'), 'whatever-123');
    await tester.tap(fieldByKey('login.submit'));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
    verify(() => app.repo.resendVerification('new@example.com')).called(1);
    // Let the resend cooldown timer finish so the test ends cleanly.
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('a restored session skips the login screen and logout returns to it', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrange: (repo) => when(() => repo.logout()).thenAnswer((_) async {}),
    );
    expect(find.byType(HomeShell), findsOneWidget);
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    expect(find.text('سارة أحمد'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('تسجيل الخروج'), 100);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    verify(() => app.repo.logout()).called(1);
  });
}
