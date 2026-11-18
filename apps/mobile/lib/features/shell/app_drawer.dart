import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/optional_asset.dart';

/// The shell's places (v3 §1). [branch] is the [StatefulShellRoute] branch index in the router; a
/// place with a [route] instead is a screen pushed over the shell (branch -1).
@immutable
class ShellPlace {
  const ShellPlace(this.branch, this.destination) : route = null;

  const ShellPlace.route(String this.route, this.destination) : branch = -1;

  final int branch;
  final String? route;
  final PlengoNavDestination destination;
}

/// Branch indices of the tab shell (see `buildRouter`). The first five are the bottom bar, in order.
abstract final class ShellBranch {
  static const home = 0, subjects = 1, practice = 2, mySubjects = 3, account = 4;
  static const review = 5, saved = 6, plengoCards = 7, makeCards = 8;

  /// Bottom bar tabs: الرئيسية · المواد · تدرّب · موادي · حسابي.
  static const bottomBarCount = 5;
}

const _home = PlengoNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'الرئيسية');
const _subjects = PlengoNavDestination(
  icon: Icons.menu_book_outlined,
  selectedIcon: Icons.menu_book_rounded,
  label: 'المواد',
);
const _practice = PlengoNavDestination(
  icon: Icons.fact_check_outlined,
  selectedIcon: Icons.fact_check_rounded,
  label: 'تدرّب',
);
const _mySubjects = PlengoNavDestination(
  icon: Icons.school_outlined,
  selectedIcon: Icons.school_rounded,
  label: 'موادي',
);
const _account = PlengoNavDestination(
  icon: Icons.person_outline_rounded,
  selectedIcon: Icons.person_rounded,
  label: 'حسابي',
);

/// Bottom bar destinations, index = branch.
const bottomBarDestinations = [_home, _subjects, _practice, _mySubjects, _account];

/// Drawer (and wide-screen rail) rows in the owner's order; نقاطي, المحفوظات and المراجعة sit under a
/// divider. نقاطي is left out while loyalty is off (see [visibleDrawerPlaces]).
const drawerPlaces = [
  ShellPlace(ShellBranch.home, _home),
  ShellPlace(ShellBranch.subjects, _subjects),
  ShellPlace(ShellBranch.mySubjects, _mySubjects),
  ShellPlace(ShellBranch.practice, _practice),
  ShellPlace(
    ShellBranch.plengoCards,
    PlengoNavDestination(icon: Icons.style_outlined, selectedIcon: Icons.style_rounded, label: 'فلاش كاردز بلينغو'),
  ),
  ShellPlace(
    ShellBranch.makeCards,
    PlengoNavDestination(
      icon: Icons.add_card_outlined,
      selectedIcon: Icons.add_card_rounded,
      label: 'اصنع بطاقاتك الخاصة',
    ),
  ),
  ShellPlace(ShellBranch.account, _account),
  ShellPlace.route(
    Routes.loyalty,
    PlengoNavDestination(icon: Icons.star_outline_rounded, selectedIcon: Icons.star_rounded, label: 'نقاطي'),
  ),
  ShellPlace(
    ShellBranch.saved,
    PlengoNavDestination(icon: Icons.bookmark_border_rounded, selectedIcon: Icons.bookmark_rounded, label: 'المحفوظات'),
  ),
  ShellPlace(
    ShellBranch.review,
    PlengoNavDestination(icon: Icons.replay_outlined, selectedIcon: Icons.replay_rounded, label: 'المراجعة'),
  ),
];

/// Index in [drawerPlaces] of the divider (before نقاطي, or المحفوظات when نقاطي is hidden).
const drawerDividerBefore = 7;

/// [drawerPlaces] without نقاطي unless [loyalty] is on.
List<ShellPlace> visibleDrawerPlaces({required bool loyalty}) => [
  for (final p in drawerPlaces)
    if (loyalty || p.route != Routes.loyalty) p,
];

/// The drawer's illustration slot (600 × 900 transparent PNG, sent by the owner).
const drawerArtAsset = 'assets/brand/drawer_art.png';

/// Lets the main screens open the shell's drawer from their app bar (☰). Absent on wide screens,
/// where the menu is a permanent rail, and outside the shell.
class ShellMenuScope extends InheritedWidget {
  const ShellMenuScope({super.key, required this.openMenu, required super.child});

  final VoidCallback openMenu;

  static ShellMenuScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShellMenuScope>();

  @override
  bool updateShouldNotify(ShellMenuScope oldWidget) => openMenu != oldWidget.openMenu;
}

/// ☰ at the start of a main screen's app bar; nothing when there is no drawer (wide screens).
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  /// The app-bar `leading` for a main screen: the ☰ button, or null when there is no drawer.
  static Widget? leadingOf(BuildContext context) =>
      ShellMenuScope.maybeOf(context) == null ? null : const DrawerMenuButton();

  @override
  Widget build(BuildContext context) {
    final scope = ShellMenuScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Center(
        child: PlengoIconButton(
          key: const Key('shell.menu'),
          icon: Icons.menu_rounded,
          tooltip: 'القائمة',
          onPressed: scope.openMenu,
        ),
      ),
    );
  }
}

/// The drawer illustration: the owner's PNG when bundled, else a placeholder of brand shapes (a soft
/// yellow hill, a stack of books and confetti dots).
class DrawerArt extends StatelessWidget {
  const DrawerArt({super.key});

  @override
  Widget build(BuildContext context) => const OptionalAssetImage(
    path: drawerArtAsset,
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    placeholder: _DrawerArtPlaceholder(),
  );
}

class _DrawerArtPlaceholder extends StatelessWidget {
  const _DrawerArtPlaceholder();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    Widget book(double w, Color c) => Container(
      width: w,
      height: 20,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
    );
    Widget dot(double d, Color c) => Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Stack(
      key: const Key('drawer.art.placeholder'),
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: -40,
          right: -40,
          bottom: -70,
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: s.isDark ? PlengoColors.yellow.base.withValues(alpha: 0.18) : PlengoColors.yellow.soft,
              borderRadius: const BorderRadius.vertical(top: Radius.elliptical(220, 110)),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 26,
          start: 0,
          end: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              book(92, PlengoColors.blue.base),
              const SizedBox(height: 3),
              book(104, PlengoColors.pink.base),
              const SizedBox(height: 3),
              book(96, PlengoColors.yellow.base),
            ],
          ),
        ),
        PositionedDirectional(top: 18, end: 36, child: dot(12, PlengoColors.yellow.base)),
        PositionedDirectional(top: 44, start: 40, child: dot(8, PlengoColors.pink.base)),
        PositionedDirectional(top: 70, end: 70, child: dot(10, PlengoColors.blue.base)),
        PositionedDirectional(bottom: 110, start: 24, child: dot(7, PlengoColors.green.base)),
      ],
    );
  }
}
