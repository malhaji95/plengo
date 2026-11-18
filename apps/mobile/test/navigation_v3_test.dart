import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/features/bookmarks/saved_tab.dart';
import 'package:plengo/features/make_cards/make_cards_screen.dart';
import 'package:plengo/features/my_subjects/my_subjects_screen.dart';
import 'package:plengo/features/plengo_cards/plengo_cards_screen.dart';
import 'package:plengo/features/practice/practice_screen.dart';
import 'package:plengo/features/quizzes/random_practice_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'helpers.dart';

/// v3 navigation (V3_PLAN §1): five bottom tabs, the side drawer with every place (active row yellow)
/// and the permanent rail on wide screens; the new routes and placeholders.
void main() {
  setUpAll(registerFallbacks);

  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder drawer() => find.byKey(const Key('shell.drawer'));
  Finder inDrawer(String label) => find.descendant(of: drawer(), matching: find.text(label));
  Color? rowColor(WidgetTester tester, Finder label) =>
      tester.widget<Material>(find.ancestor(of: label, matching: find.byType(Material)).first).color;

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('shell.menu')).first);
    await tester.pumpAndSettle();
  }

  const bottomTabs = ['الرئيسية', 'المواد', 'تدرّب', 'موادي', 'حسابي'];
  const drawerRows = [
    'الرئيسية',
    'المواد',
    'موادي',
    'تدرّب',
    'فلاش كاردز بلينغو',
    'اصنع بطاقاتك الخاصة',
    'حسابي',
    'المحفوظات',
    'المراجعة',
  ];

  testWidgets('the bottom bar holds the five main places and selects the open one', (tester) async {
    useSize(tester, const Size(390, 844));
    await pumpApp(tester, signedInAs: testMe);
    final bar = find.byType(PlengoNavBar);
    for (final label in bottomTabs) {
      expect(find.descendant(of: bar, matching: find.text(label)), findsOneWidget);
    }
    // Right to left in RTL: the first tab sits at the start (right) edge.
    final x = [for (final l in bottomTabs) tester.getCenter(find.descendant(of: bar, matching: find.text(l))).dx];
    for (var i = 1; i < x.length; i++) {
      expect(x[i], lessThan(x[i - 1]));
    }
    expect(tester.widget<PlengoNavBar>(bar).selectedIndex, 0);

    await tester.tap(find.descendant(of: bar, matching: find.text('تدرّب')));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeHomeScreen), findsOneWidget);
    expect(find.text('قريباً'), findsOneWidget);
    expect(tester.widget<PlengoNavBar>(bar).selectedIndex, 2);

    await tester.tap(find.descendant(of: bar, matching: find.text('موادي')));
    await tester.pumpAndSettle();
    expect(find.byType(MySubjectsScreen), findsOneWidget);
    expect(tester.widget<PlengoNavBar>(bar).selectedIndex, 3);
  });

  testWidgets('☰ opens the drawer: every place, the active one yellow; a row navigates', (tester) async {
    useSize(tester, const Size(390, 844));
    await pumpApp(tester, signedInAs: testMe);
    expect(drawer(), findsNothing);
    expect(find.bySemanticsLabel('القائمة'), findsOneWidget);
    await openDrawer(tester);

    expect(drawer(), findsOneWidget);
    final y = [for (final l in drawerRows) tester.getCenter(inDrawer(l)).dy];
    for (var i = 1; i < y.length; i++) {
      expect(y[i], greaterThan(y[i - 1]), reason: drawerRows[i]);
    }
    expect(rowColor(tester, inDrawer('الرئيسية')), PlengoColors.yellow.base);
    expect(rowColor(tester, inDrawer('المحفوظات')), Colors.transparent);
    expect(tester.getSemantics(inDrawer('الرئيسية')), isSemantics(isSelected: true));
    // The illustration slot shows its placeholder until the owner's PNG is bundled.
    expect(find.descendant(of: drawer(), matching: find.byKey(const Key('drawer.art.placeholder'))), findsOneWidget);

    await tester.tap(inDrawer('المحفوظات'));
    await tester.pumpAndSettle();
    expect(drawer(), findsNothing);
    expect(find.byType(SavedTab), findsOneWidget);
    // A place outside the bar selects no tab.
    expect(tester.widget<PlengoNavBar>(find.byType(PlengoNavBar)).selectedIndex, -1);

    await openDrawer(tester);
    expect(rowColor(tester, inDrawer('المحفوظات')), PlengoColors.yellow.base);
    expect(rowColor(tester, inDrawer('الرئيسية')), Colors.transparent);
    await tester.tap(inDrawer('فلاش كاردز بلينغو'));
    await tester.pumpAndSettle();
    expect(find.byType(PlengoCardsScreen), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(inDrawer('اصنع بطاقاتك الخاصة'));
    await tester.pumpAndSettle();
    expect(find.byType(MakeCardsScreen), findsOneWidget);

    await openDrawer(tester);
    await tester.tap(inDrawer('المراجعة'));
    await tester.pumpAndSettle();
    expect(find.text('المراجعة'), findsWidgets);
    expect(tester.widget<PlengoNavBar>(find.byType(PlengoNavBar)).selectedIndex, -1);
  });

  testWidgets('wide screens: the drawer is a permanent rail with every place, and no ☰', (tester) async {
    useSize(tester, const Size(1280, 900));
    await pumpApp(tester, signedInAs: testMe);
    final rail = find.byKey(const Key('shell.rail'));
    expect(rail, findsOneWidget);
    expect(find.byType(PlengoNavBar), findsNothing);
    expect(find.byKey(const Key('shell.menu')), findsNothing);
    for (final l in drawerRows) {
      expect(find.descendant(of: rail, matching: find.text(l)), findsOneWidget);
    }
    await tester.tap(find.descendant(of: rail, matching: find.text('موادي')));
    await tester.pumpAndSettle();
    expect(find.byType(MySubjectsScreen), findsOneWidget);
    expect(rowColor(tester, find.descendant(of: rail, matching: find.text('موادي'))), PlengoColors.yellow.base);
  });

  testWidgets('new routes open their screens; /practice/random still opens random practice', (tester) async {
    useSize(tester, const Size(390, 844));
    final app = await pumpApp(tester, signedInAs: testMe);
    final router = app.container.read(routerProvider);
    Future<void> go(String location) async {
      router.go(location);
      await tester.pumpAndSettle();
    }

    await go('/practice/p1');
    expect(tester.widget<PracticeSetupScreen>(find.byType(PracticeSetupScreen)).subjectId, 'p1');
    await go(Routes.practiceDiagrams);
    expect(find.byType(DiagramsScreen), findsOneWidget);
    await go('${Routes.plengoCards}?subjectId=p1');
    expect(tester.widget<PlengoCardsScreen>(find.byType(PlengoCardsScreen)).subjectId, 'p1');
    await go('${Routes.makeCardsGroups}?subjectId=p1');
    expect(tester.widget<MyGroupsScreen>(find.byType(MyGroupsScreen)).subjectId, 'p1');
    await go(Routes.mySubjects);
    expect(find.byType(MySubjectsScreen), findsOneWidget);
    await go('${Routes.saved}?filter=cards&subjectId=p1');
    final saved = tester.widget<SavedTab>(find.byType(SavedTab));
    expect((saved.filter, saved.subjectId), ('cards', 'p1'));

    router.go('${Routes.randomPractice}?subjectId=p1');
    await tester.pump();
    expect(find.byType(RandomPracticeScreen), findsOneWidget);
    expect(find.byType(PracticeSetupScreen), findsNothing);
  });
}
