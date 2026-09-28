import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/features/auth/login_screen.dart';
import 'package:plengo/features/legal/legal_screen.dart';

import 'helpers.dart';

const _privacy = '# سياسة الخصوصية\n\nمقدمة.\n\n## البيانات\n\n- الاسم\n- البريد\n';

Future<void> openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.text('حسابي').last);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('حذف الحساب'), 100);
  await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text('حذف الحساب'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerFallbacks);

  test('legal texts: headings, list items and paragraphs', () {
    final blocks = parseLegal(_privacy);
    expect(blocks.map((b) => b.runtimeType).toList(), [
      LegalHeading,
      LegalParagraph,
      LegalHeading,
      LegalItem,
      LegalItem,
    ]);
    expect((blocks[2] as LegalHeading).level, 2);
    expect(blocks[4].text, 'البريد');
  });

  testWidgets('deleting the account needs the password, then wipes the device and signs out (§33)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrange: (repo) {
        when(() => repo.deleteAccount('wrong')).thenThrow(const ApiException('AUTH_INVALID_CREDENTIALS', 'x'));
        when(() => repo.deleteAccount('correct-horse')).thenAnswer((_) async {});
      },
    );
    await app.db.setValue('probe', 'kept-until-deletion');
    await openDeleteDialog(tester);
    expect(find.text('حذف الحساب نهائياً'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'حذف الحساب');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('delete.password')), 'wrong');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('كلمة المرور غير صحيحة'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.enterText(find.byKey(const Key('delete.password')), 'correct-horse');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    verify(() => app.repo.deleteAccount('correct-horse')).called(1);
    verifyNever(() => app.repo.logout());
    expect(await app.db.getValue('probe'), isNull);
  });

  testWidgets('cancelling keeps the account', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe);
    await openDeleteDialog(tester);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('حذف الحساب نهائياً'), findsNothing);
    verifyNever(() => app.repo.deleteAccount(any()));
  });

  testWidgets('privacy and terms open from registration while signed out', (tester) async {
    final app = await pumpApp(
      tester,
      extraOverrides: [
        legalTextProvider.overrideWith(
          (ref, doc) async => doc == LegalDocument.privacy ? _privacy : '# شروط الاستخدام\n\nنص الشروط.',
        ),
      ],
    );
    app.container.read(routerProvider).go(Routes.register);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('سياسة الخصوصية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سياسة الخصوصية'));
    await tester.pumpAndSettle();
    expect(find.text('البيانات'), findsOneWidget);
    expect(find.text('البريد'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('شروط الاستخدام'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شروط الاستخدام'));
    await tester.pumpAndSettle();
    expect(find.text('نص الشروط.'), findsOneWidget);
  });

  testWidgets('a signed-in student reaches the policy at /privacy directly', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      extraOverrides: [legalTextProvider.overrideWith((ref, doc) async => _privacy)],
    );
    app.container.read(routerProvider).go(Routes.privacy);
    await tester.pumpAndSettle();
    expect(find.text('مقدمة.'), findsOneWidget);
  });
}
