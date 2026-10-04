import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/features/auth/login_screen.dart';
import 'package:plengo/features/onboarding/onboarding.dart';

import 'helpers.dart';

void main() {
  testWidgets('first launch shows the intro once; skipping it opens login and it never returns', (tester) async {
    final app = await pumpApp(tester, onboardingSeen: false);
    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.text('رحلتك التعليمية أسهل مع Plengo'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('تعلّم بطريقتك'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsNothing);
    expect(find.text('تسجيل الدخول'), findsWidgets);
    expect(await app.container.read(onboardingSeenProvider.future), isTrue);
  });

  testWidgets('the last intro page starts the app with ابدأ الآن', (tester) async {
    await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('حقّق أهدافك'), findsOneWidget);
    expect(find.text('تخطي'), findsNothing);
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
  });

  testWidgets('a returning device goes straight to login', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingView), findsNothing);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
