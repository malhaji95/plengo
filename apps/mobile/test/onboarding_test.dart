import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/features/auth/login_screen.dart';
import 'package:plengo/features/auth/register_screen.dart';
import 'package:plengo/features/onboarding/onboarding.dart';

import 'helpers.dart';

void main() {
  testWidgets('first launch shows the intro once; skipping it opens login and it never returns', (tester) async {
    final app = await pumpApp(tester, onboardingSeen: false);
    expect(find.byType(OnboardingView), findsOneWidget);
    expect(find.text('رحلتك التعليمية أسهل مع Plengo'), findsOneWidget);
    expect(find.bySemanticsLabel('الصفحة 1 من 3'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('تعلّم بطريقتك'), findsOneWidget);
    expect(find.bySemanticsLabel('الصفحة 2 من 3'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingView), findsNothing);
    expect(fieldByKey('login.email'), findsOneWidget);
    expect(await app.container.read(onboardingSeenProvider.future), isTrue);
  });

  testWidgets('the last page: «تخطي» stays, «ابدأ الآن» opens registration', (tester) async {
    final app = await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('حقّق أهدافك'), findsOneWidget);
    expect(find.text('تخطي'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(await app.container.read(onboardingSeenProvider.future), isTrue);
    // Back from registration lands on the login form, not the intro.
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
  });

  testWidgets('«لدي حساب — تسجيل الدخول» marks the intro seen and shows login', (tester) async {
    final app = await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لدي حساب — تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(OnboardingView), findsNothing);
    expect(await app.container.read(onboardingSeenProvider.future), isTrue);
  });

  testWidgets('with reduced motion the intro jumps between pages', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, onboardingSeen: false);
    await tester.tap(find.text('التالي'));
    await tester.pump();
    expect(find.text('تعلّم بطريقتك'), findsOneWidget);
    expect(find.text('رحلتك التعليمية أسهل مع Plengo'), findsNothing);
  });

  testWidgets('a returning device goes straight to login', (tester) async {
    await pumpApp(tester);
    expect(find.byType(OnboardingView), findsNothing);
    expect(find.byType(TextField), findsWidgets);
  });
}
