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
/// rows; the active row is filled yellow with dark bold text. The same menu fills the side drawer on
/// phones (v3 §1): a divider can split the rows ([dividerBefore]) and an illustration ([footer]) sits
/// at the bottom when there is room. [selectedIndex] outside the list selects nothing.
class PlengoSideRail extends StatelessWidget {
  const PlengoSideRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.dividerBefore,
    this.footer,
    this.footerHeight = 180,
    this.width = PlengoSpace.railWidth,
    this.border = true,
  });

  final List<PlengoNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Replaces the logo.
  final Widget? header;

  /// A divider is drawn before the row at this index.
  final int? dividerBefore;

  /// Decoration under the rows (the drawer illustration), [footerHeight] high.
  final Widget? footer;
  final double footerHeight;
  final double width;

  /// The end-edge line (off inside a drawer, which has its own edge).
  final bool border;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'التنقل الرئيسي',
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: s.card,
          border: border ? BorderDirectional(end: BorderSide(color: s.line)) : null,
        ),
        child: SafeArea(
          right: false,
          left: false,
          child: LayoutBuilder(
            builder: (context, box) {
              // Long menus (the v3 drawer) sit tighter so they fit a laptop window without scrolling.
              final compact = destinations.length > 6;
              final gap = compact ? 2.0 : 6.0;
              final logoGap = compact ? 16.0 : 24.0;
              final top = compact ? 20.0 : 28.0;
              final rows = <Widget>[
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(8, 0, 8, logoGap),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: header ?? const BrandLogo(height: 40),
                  ),
                ),
                for (final (i, d) in destinations.indexed) ...[
                  if (i == dividerBefore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: s.line),
                    )
                  else if (i > 0)
                    SizedBox(height: gap),
                  _RailRow(destination: d, selected: i == selectedIndex, onTap: () => onSelected(i)),
                ],
              ];
              // Scrolls only on very short windows, so the rail adds no scrollable to normal layouts; the
              // illustration shows only when there is room left for it.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final needed =
                  (destinations.length * (PlengoSpace.railRow + gap) + (dividerBefore == null ? 0 : 17)) * scale +
                  40 +
                  logoGap +
                  top +
                  16 +
                  (compact ? 0 : 44);
              final padding = EdgeInsetsDirectional.fromSTEB(16, top, 16, 16);
              // Very short windows scroll. Otherwise the rows shrink a little rather than overflow when they
              // run longer than estimated (long labels, large text), so no scrollable is added.
              if (box.maxHeight < needed * 0.75) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: padding,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
                  ),
                );
              }
              final art = footer == null || box.maxHeight < needed + footerHeight
                  ? null
                  : ExcludeSemantics(
                      child: SizedBox(height: footerHeight, child: footer),
                    );
              final width = box.maxWidth - 32;
              return Padding(
                padding: art == null ? padding : EdgeInsetsDirectional.fromSTEB(16, top, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.topStart,
                        child: SizedBox(
                          width: width,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: rows,
                          ),
                        ),
                      ),
                    ),
                    ?art,
                  ],
                ),
              );
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
