import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/features/auth/login_screen.dart';
import 'package:plengo/features/auth/verify_email_screen.dart';
import 'package:plengo/features/auth/goal_step_marker.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/features/onboarding/goal_step_screen.dart';
import 'package:plengo/features/shell/home_shell.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

void main() {
  testWidgets('signed-out users land on the Arabic RTL login screen', (tester) async {
    await pumpApp(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('أهلاً بعودتك!'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
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
    // V-LoginError: the message sits under the password field with an alert icon and a recovery hint.
    expect(find.text('تحقّق منها، أو استخدم «نسيت كلمة المرور؟».'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    final password = tester.getRect(fieldByKey('login.password'));
    final message = tester.getRect(find.text('بيانات الدخول غير صحيحة'));
    expect(message.top, greaterThanOrEqualTo(password.bottom));
    expect(message.top, lessThan(tester.getRect(find.text('نسيت كلمة المرور؟')).top));
    final field = tester.widget<TextField>(fieldByKey('login.password'));
    expect((field.decoration!.enabledBorder! as OutlineInputBorder).borderSide.color, PlengoColors.redStrong);
    expect(field.decoration!.fillColor, PlengoColors.red.soft);
    // Typing again clears the server error.
    await tester.enterText(fieldByKey('login.password'), 'another-try');
    await tester.pump();
    expect(find.text('بيانات الدخول غير صحيحة'), findsNothing);
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
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    verify(() => app.repo.logout()).called(1);
  });

  void arrangeVerifyAndLogin(MockAuthRepository repo) {
    when(
      () => repo.verifyEmail(
        email: any(named: 'email'),
        otp: any(named: 'otp'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
        appVersion: any(named: 'appVersion'),
      ),
    ).thenAnswer((_) async => testMe);
    when(() => repo.logout()).thenAnswer((_) async {});
  }

  Future<void> login(WidgetTester tester) async {
    await tester.enterText(fieldByKey('login.password'), 'correct-horse');
    await tester.ensureVisible(fieldByKey('login.submit'));
    await tester.tap(fieldByKey('login.submit'));
    await tester.pumpAndSettle();
  }

  testWidgets('the first login after verifying opens the daily-goal step once (newDailyGoalStep)', (tester) async {
    final app = await pumpApp(tester, arrange: arrangeVerifyAndLogin);
    app.container
        .read(routerProvider)
        .go(Uri(path: Routes.verifyEmail, queryParameters: {'email': 'new@example.com'}).toString());
    await tester.pumpAndSettle();

    // Pasting / autofilling the whole code fills the six LTR boxes.
    await tester.enterText(fieldByKey('verify.otp'), '١٢٣٤٥٦');
    await tester.pump();
    expect(tester.widget<TextField>(fieldByKey('verify.otp')).controller!.text, '123456');
    await tester.tap(fieldByKey('verify.submit'));
    await tester.pumpAndSettle();
    verify(() => app.repo.verifyEmail(email: 'new@example.com', otp: '123456')).called(1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await GoalStepMarker.isPending(app.db), isTrue);

    await login(tester);
    expect(find.byType(GoalStepScreen), findsOneWidget);
    expect(app.container.read(routerProvider).state.uri.path, Routes.onboardingGoal);
    expect(await GoalStepMarker.isPending(app.db), isFalse);
  });

  testWidgets('a login without a fresh verification goes straight to Home', (tester) async {
    final app = await pumpApp(tester, arrange: arrangeVerifyAndLogin);
    await tester.enterText(fieldByKey('login.email'), 'student@example.com');
    await login(tester);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(GoalStepScreen), findsNothing);
    expect(await GoalStepMarker.isPending(app.db), isFalse);
  });

  testWidgets('a wrong code is explained under the boxes and keeps the marker unset', (tester) async {
    final app = await pumpApp(
      tester,
      arrange: (repo) => when(
        () => repo.verifyEmail(
          email: any(named: 'email'),
          otp: any(named: 'otp'),
        ),
      ).thenThrow(const ApiException('AUTH_OTP_INVALID', 'رمز التحقق غير صحيح أو منتهي')),
    );
    app.container
        .read(routerProvider)
        .go(Uri(path: Routes.verifyEmail, queryParameters: {'email': 'new@example.com'}).toString());
    await tester.pumpAndSettle();
    await tester.enterText(fieldByKey('verify.otp'), '000000');
    await tester.tap(fieldByKey('verify.submit'));
    await tester.pumpAndSettle();
    expect(find.text('رمز التحقق غير صحيح أو منتهي'), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(await GoalStepMarker.isPending(app.db), isFalse);
    // The resend countdown runs for 60 s, then the link comes back.
    expect(find.textContaining('إعادة إرسال الرمز بعد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('إعادة إرسال الرمز'), findsOneWidget);
  });
}
