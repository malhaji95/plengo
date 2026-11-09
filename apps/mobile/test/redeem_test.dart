import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/access/redeem_screen.dart';
import 'package:plengo/features/subjects/subject_screen.dart';
import 'package:plengo/features/subjects/subjects_screen.dart';

import 'helpers.dart';

SubjectOutline lockedOutline() => SubjectOutline(
  subject: subject('p', 'الفيزياء'),
  units: const [],
  lessons: const [],
  tracks: const [],
  access: noAccess,
  questionCount: noQuestions,
  deckCount: noQuestions,
  quizCount: noQuestions,
);

String location(PumpedApp app) => app.container.read(routerProvider).state.uri.toString();

void main() {
  testWidgets('coming from a locked subject: the notice names it and «جرّب الدروس المجانية أولاً» goes back to it', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => lockedOutline()),
    );
    app.container.read(routerProvider).go(Uri(path: Routes.redeem, queryParameters: {'subjectId': 'p'}).toString());
    await tester.pumpAndSettle();
    expect(find.byType(RedeemScreen), findsOneWidget);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.ensureVisible(find.text('جرّب الدروس المجانية أولاً'));
    await tester.tap(find.text('جرّب الدروس المجانية أولاً'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectScreen), findsOneWidget);
    expect(location(app), '${Routes.subjects}/p');
  });

  testWidgets('the origin can also come as a route extra', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer((_) async => lockedOutline()),
    );
    app.container.read(routerProvider).go(Routes.redeem, extra: {'subjectId': 'p'});
    await tester.pumpAndSettle();
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsOneWidget);
    await tester.ensureVisible(find.text('جرّب الدروس المجانية أولاً'));
    await tester.tap(find.text('جرّب الدروس المجانية أولاً'));
    await tester.pumpAndSettle();
    expect(location(app), '${Routes.subjects}/p');
  });

  testWidgets('opened from the account: no locked notice, and the ghost button opens the Subjects tab', (tester) async {
    final app = await pumpApp(tester, signedInAs: testMe);
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    await tester.tap(find.text('إدخال كود التفعيل'));
    await tester.pumpAndSettle();
    expect(find.byType(RedeemScreen), findsOneWidget);
    expect(find.text('هذا المحتوى يحتاج إلى تفعيل'), findsNothing);
    // The big centred code field is LTR and formats as XXXX-XXXX-XX, Arabic digits included.
    await tester.enterText(find.byKey(const Key('coupon-code')), 'abcd٢٣٤٥xy');
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const Key('coupon-code')));
    expect(field.controller!.text, 'ABCD-2345-XY');
    expect(field.textDirection, TextDirection.ltr);
    expect(field.textAlign, TextAlign.center);

    await tester.ensureVisible(find.text('جرّب الدروس المجانية أولاً'));
    await tester.tap(find.text('جرّب الدروس المجانية أولاً'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectsScreen), findsOneWidget);
    expect(location(app), Routes.subjects);
  });

  testWidgets('success: green check, the access date and «الذهاب إلى المحتوى»', (tester) async {
    const scope = AccessScope(
      scopeType: AccessScopeScopeType.subject,
      subjectId: 'p',
      subjectNameAr: 'الفيزياء',
      teacherTrackId: null,
      trackTitleAr: null,
      teacherNameAr: null,
      educationLevelId: 'l12',
    );
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeAccess: (a) => when(() => a.redeem(any())).thenAnswer(
        (_) async => const RedeemResult(
          entitlement: MyEntitlement(
            id: 'e1',
            scope: scope,
            state: MyEntitlementState.active,
            isPermanent: false,
            startsAt: '2026-09-01T00:00:00.000Z',
            expiresAt: '2027-06-30T20:59:59.000Z',
            source: MyEntitlementSource.coupon,
          ),
          upgraded: false,
        ),
      ),
    );
    app.container.read(routerProvider).go(Routes.redeem);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('coupon-code')), 'ABCD2345XY');
    await tester.pump();
    await tester.tap(find.text('تفعيل'));
    await tester.pumpAndSettle();
    expect(find.text('تم التفعيل بنجاح'), findsOneWidget);
    expect(find.text('حتى 2027/6/30'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('الذهاب إلى المحتوى'), findsOneWidget);
  });
}
