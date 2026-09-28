import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/shared/widgets/responsive.dart';

import 'helpers.dart';

/// Web and tablet layouts (spec §24): rail above 600 px, list grids, 720 px reading width, and the
/// online-only notice when the browser has no persistent storage.
void main() {
  setUpAll(registerFallbacks);

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('one column on phones, up to three on wide screens', () {
    expect(ResponsiveList.columnsFor(390), 1);
    expect(ResponsiveList.columnsFor(599), 1);
    expect(ResponsiveList.columnsFor(700), 2);
    expect(ResponsiveList.columnsFor(1100), 3);
    expect(ResponsiveList.columnsFor(2400), 3);
  });

  testWidgets('phones get a bottom bar; wide screens a rail, a subject grid and capped reading width', (tester) async {
    useSize(tester, const Size(1280, 900));
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) => when(
        () => c.subjects(any()),
      ).thenAnswer((_) async => [subject('p', 'الفيزياء'), subject('m', 'الرياضيات'), subject('c', 'الكيمياء')]),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Home content is at most 720 px wide.
    expect(tester.getSize(find.byType(ListView).first).width, lessThanOrEqualTo(kContentMaxWidth));

    await tester.tap(find.text('المواد').last);
    await tester.pumpAndSettle();
    final physics = tester.getRect(find.text('الفيزياء'));
    final maths = tester.getRect(find.text('الرياضيات'));
    // Side by side: same row, different columns.
    expect(physics.top, closeTo(maths.top, 1));
    expect(physics.left, isNot(closeTo(maths.left, 50)));
  });

  testWidgets('a phone-width window keeps the bottom bar and a single column', (tester) async {
    useSize(tester, const Size(390, 844));
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeCatalog: (c) =>
          when(() => c.subjects(any())).thenAnswer((_) async => [subject('p', 'الفيزياء'), subject('m', 'الرياضيات')]),
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('المواد').last);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('الفيزياء')).top, lessThan(tester.getRect(find.text('الرياضيات')).top));
  });

  testWidgets('without persistent browser storage the app says it works online only', (tester) async {
    final ephemeral = ValueNotifier<bool>(false);
    await pumpApp(tester, signedInAs: testMe, extraOverrides: [ephemeralStorageProvider.overrideWithValue(ephemeral)]);
    const notice = 'متصفحك لا يسمح بالتخزين المحلي، لذلك يعمل التطبيق متصلاً فقط ولن تُحفظ المراجعة دون اتصال.';
    expect(find.text(notice), findsNothing);
    ephemeral.value = true;
    await tester.pump();
    expect(find.text(notice), findsOneWidget);
    // The notice stays while moving between tabs.
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    expect(find.text(notice), findsOneWidget);
  });
}
