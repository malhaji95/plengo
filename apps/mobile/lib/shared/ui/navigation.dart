import 'package:flutter/material.dart';

import '../widgets/brand_logo.dart';
import 'tokens.dart';

/// One destination of [PlengoNavBar] and [PlengoSideRail].
@immutable
class PlengoNavDestination {
  const PlengoNavDestination({required this.icon, required this.selectedIcon, required this.label});

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bottom navigation for phones (spec §4): icon 22 + label 11; the active tab has a yellow 58 × 32 pill
/// behind its icon and a bold label. Card background with a top border.
class PlengoNavBar extends StatelessWidget {
  const PlengoNavBar({super.key, required this.destinations, required this.selectedIndex, required this.onSelected});

  final List<PlengoNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'التنقل الرئيسي',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.nav,
          border: Border(top: BorderSide(color: s.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Row(
              children: [
                for (final (i, d) in destinations.indexed)
                  Expanded(
                    child: _NavTab(
                      destination: d,
                      selected: i == selectedIndex,
                      index: i,
                      count: destinations.length,
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.selected,
    required this.index,
    required this.count,
    required this.onTap,
  });

  final PlengoNavDestination destination;
  final bool selected;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      hint: 'التبويب ${index + 1} من $count',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlengoRadius.iconButton),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: PlengoMotion.of(context, PlengoMotion.press),
                width: PlengoSpace.navPillWidth,
                height: PlengoSpace.navPillHeight,
                decoration: BoxDecoration(
                  color: selected ? PlengoColors.yellow.base : Colors.transparent,
                  borderRadius: BorderRadius.circular(PlengoRadius.pill),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: selected ? PlengoColors.ink : s.mute,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PlengoType.navLabel.copyWith(
                  color: selected ? s.ink : s.mute,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side rail for wide layouts (≥ 600 dp, spec §4): 240 wide at the start edge, the logo on top, 52-high
/// rows; the active row is filled yellow with dark bold text.
class PlengoSideRail extends StatelessWidget {
  const PlengoSideRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
  });

  final List<PlengoNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Replaces the logo.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'التنقل الرئيسي',
      child: Container(
        width: PlengoSpace.railWidth,
        decoration: BoxDecoration(
          color: s.card,
          border: BorderDirectional(end: BorderSide(color: s.line)),
        ),
        child: SafeArea(
          right: false,
          left: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final column = Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 28, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 24),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: header ?? const BrandLogo(height: 40),
                      ),
                    ),
                    for (final (i, d) in destinations.indexed) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _RailRow(destination: d, selected: i == selectedIndex, onTap: () => onSelected(i)),
                    ],
                  ],
                ),
              );
              // Scrolls only on very short windows, so the rail adds no scrollable to normal layouts.
              final rows = destinations.length * (PlengoSpace.railRow + 6) + 140;
              return box.maxHeight < rows * MediaQuery.textScalerOf(context).scale(1)
                  ? SingleChildScrollView(child: column)
                  : column;
            },
          ),
        ),
      ),
    );
  }
}

class _RailRow extends StatelessWidget {
  const _RailRow({required this.destination, required this.selected, required this.onTap});

  final PlengoNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final fg = selected ? PlengoColors.ink : s.ink;
    final r = BorderRadius.circular(PlengoRadius.iconButton);
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? PlengoColors.yellow.base : Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PlengoSpace.railRow),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(selected ? destination.selectedIcon : destination.icon, size: 22, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destination.label,
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
