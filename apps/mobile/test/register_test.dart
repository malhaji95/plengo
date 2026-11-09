import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/features/auth/register_screen.dart';
import 'package:plengo/features/auth/verify_email_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.ensureVisible(find.text('أنشئ حساباً جديداً'));
  await tester.tap(find.text('أنشئ حساباً جديداً'));
  await tester.pumpAndSettle();
  expect(find.byType(RegisterScreen), findsOneWidget);
}

bool pillSelected(WidgetTester tester, String label) =>
    tester.widget<PlengoPill>(find.widgetWithText(PlengoPill, label)).selected;

void main() {
  testWidgets('validates password length, confirmation and level', (tester) async {
    await pumpApp(tester);
    await openRegister(tester);
    await tester.enterText(fieldByKey('register.name'), 'علي');
    await tester.enterText(fieldByKey('register.email'), 'ali@example.com');
    await tester.enterText(fieldByKey('register.password'), 'short');
    await tester.enterText(fieldByKey('register.confirm'), 'different');
    await tester.ensureVisible(fieldByKey('register.submit'));
    await tester.tap(fieldByKey('register.submit'));
    await tester.pumpAndSettle();
    expect(find.text('يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'), findsOneWidget);
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
    expect(find.text('اختر المرحلة التعليمية'), findsOneWidget);
    // Errors are written under the field with an alert icon, not shown by colour alone.
    expect(find.byIcon(Icons.error_rounded), findsNWidgets(3));
  });

  testWidgets('stage pills come from the real education levels; college reveals the optional box', (tester) async {
    await pumpApp(tester);
    await openRegister(tester);
    for (final name in ['الصف التاسع', 'البكالوريا', 'الجامعة']) {
      expect(find.widgetWithText(PlengoPill, name), findsOneWidget);
      expect(pillSelected(tester, name), isFalse);
    }
    expect(find.text('اختياري: حدّد جامعتك وكليتك وسنتك الدراسية'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(PlengoPill, 'الجامعة'));
    await tester.tap(find.widgetWithText(PlengoPill, 'الجامعة'));
    await tester.pumpAndSettle();
    expect(pillSelected(tester, 'الجامعة'), isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('اختياري: حدّد جامعتك وكليتك وسنتك الدراسية'), findsOneWidget);
    expect(fieldByKey('placement.university'), findsOneWidget);

    await tester.tap(find.widgetWithText(PlengoPill, 'البكالوريا'));
    await tester.pumpAndSettle();
    expect(pillSelected(tester, 'البكالوريا'), isTrue);
    expect(pillSelected(tester, 'الجامعة'), isFalse);
    expect(fieldByKey('placement.university'), findsNothing);
  });

  testWidgets('registers and continues to OTP verification', (tester) async {
    final app = await pumpApp(
      tester,
      arrange: (repo) => when(
        () => repo.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          educationLevelId: any(named: 'educationLevelId'),
          universityId: any(named: 'universityId'),
          facultyId: any(named: 'facultyId'),
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer((_) async {}),
    );
    await openRegister(tester);
    await tester.enterText(fieldByKey('register.name'), 'علي محمد');
    await tester.enterText(fieldByKey('register.email'), 'Ali@Example.com');
    await tester.enterText(fieldByKey('register.password'), 'long-enough-1');
    await tester.enterText(fieldByKey('register.confirm'), 'long-enough-1');
    await tester.ensureVisible(find.widgetWithText(PlengoPill, 'البكالوريا'));
    await tester.tap(find.widgetWithText(PlengoPill, 'البكالوريا'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(fieldByKey('register.submit'));
    await tester.tap(fieldByKey('register.submit'));
    await tester.pumpAndSettle();
    verify(
      () => app.repo.register(
        fullName: 'علي محمد',
        email: 'ali@example.com',
        password: 'long-enough-1',
        educationLevelId: 'l12',
        universityId: null,
        facultyId: null,
        academicYearId: null,
      ),
    ).called(1);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('a taken email is explained under the email field', (tester) async {
    await pumpApp(
      tester,
      arrange: (repo) => when(
        () => repo.register(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          educationLevelId: any(named: 'educationLevelId'),
          universityId: any(named: 'universityId'),
          facultyId: any(named: 'facultyId'),
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenThrow(const ApiException('AUTH_EMAIL_TAKEN', 'البريد الإلكتروني مستخدم مسبقاً')),
    );
    await openRegister(tester);
    await tester.enterText(fieldByKey('register.name'), 'علي محمد');
    await tester.enterText(fieldByKey('register.email'), 'ali@example.com');
    await tester.enterText(fieldByKey('register.password'), 'long-enough-1');
    await tester.enterText(fieldByKey('register.confirm'), 'long-enough-1');
    await tester.ensureVisible(find.widgetWithText(PlengoPill, 'البكالوريا'));
    await tester.tap(find.widgetWithText(PlengoPill, 'البكالوريا'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(fieldByKey('register.submit'));
    await tester.tap(fieldByKey('register.submit'));
    await tester.pumpAndSettle();
    expect(find.text('البريد الإلكتروني مستخدم مسبقاً'), findsOneWidget);
    expect(find.text('استخدم بريداً آخر، أو سجّل الدخول بهذا البريد.'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('«تعديل البريد» on the verify screen returns to registration with the email', (tester) async {
    final app = await pumpApp(tester);
    app.container
        .read(routerProvider)
        .go(Uri(path: Routes.verifyEmail, queryParameters: {'email': 'ali@example.com'}).toString());
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await tester.tap(find.text('تعديل البريد'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    final email = tester.widget<TextField>(fieldByKey('register.email'));
    expect(email.controller!.text, 'ali@example.com');
    expect(email.textDirection, TextDirection.ltr);
  });
}
