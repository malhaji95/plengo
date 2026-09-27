import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/features/auth/register_screen.dart';
import 'package:plengo/features/auth/verify_email_screen.dart';

import 'helpers.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.tap(find.text('ليس لديك حساب؟ أنشئ حساباً جديداً'));
  await tester.pumpAndSettle();
  expect(find.byType(RegisterScreen), findsOneWidget);
}

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
    await tester.ensureVisible(fieldByKey('placement.level'));
    await tester.tap(fieldByKey('placement.level'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('البكالوريا').last);
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
}
