import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// The redesign card (spec §3): radius 24, padding 16; light mode has a soft shadow, dark mode a 1 px
/// line border instead. With [onTap] the whole card is one button.
class PlengoCard extends StatelessWidget {
  const PlengoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsetsDirectional.all(PlengoSpace.cardPadding),
    this.margin,
    this.color,
    this.radius = PlengoRadius.card,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Overrides the card colour (e.g. a soft hue). Coloured cards drop the shadow and border.
  final Color? color;
  final double radius;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(radius);
    final plain = color == null;
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: r, onTap: onTap, child: content),
      );
    }
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? s.card,
        borderRadius: r,
        border: plain && s.isDark ? Border.all(color: s.line) : null,
        boxShadow: plain ? plengoCardShadow(s) : null,
      ),
      child: ClipRRect(borderRadius: r, child: content),
    );
    if (semanticsLabel != null || onTap != null) {
      card = Semantics(container: true, button: onTap != null, label: semanticsLabel, child: card);
    }
    return card;
  }
}

/// The blue hero card (Continue on Home): radius 28, padding 20, white text and icons, decorative
/// circles at the end-top corner. The fill stays blue in dark mode; put a brand (yellow) button inside.
class PlengoHeroCard extends StatelessWidget {
  const PlengoHeroCard({super.key, required this.child, this.onTap, this.padding, this.semanticsLabel});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(PlengoRadius.hero);
    Widget body = Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(PlengoSpace.heroPadding),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, fontFamily: PlengoType.family),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: child,
        ),
      ),
    );
    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: r, onTap: onTap, child: body),
      );
    }
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ClipRRect(
        borderRadius: r,
        child: ColoredBox(
          color: PlengoColors.blue.base,
          child: Stack(
            children: [
              const PositionedDirectional(top: -50, end: -50, child: _Blob(150, PlengoColors.heroBlob)),
              PositionedDirectional(top: 22, end: 30, child: _Blob(26, PlengoColors.yellow.base)),
              PositionedDirectional(top: 58, end: 64, child: _Blob(14, PlengoColors.pink.base)),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}

/// A 28-high pill: soft background, ink text, optional 14 px icon (e.g. «مجاني», lock + «مقفل»).
class PlengoChip extends StatelessWidget {
  const PlengoChip({
    super.key,
    required this.label,
    this.hue = PlengoColors.blue,
    this.icon,
    this.background,
    this.foreground,
    this.semanticsLabel,
  });

  final String label;
  final PlengoHue hue;
  final IconData? icon;

  /// Overrides [hue]'s soft background / ink (keep to the spec's pairs).
  final Color? background;
  final Color? foreground;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? hue.ink;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: background ?? hue.soft,
          borderRadius: BorderRadius.circular(PlengoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 6)],
            Flexible(
              child: Text(label, style: PlengoType.chip.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A solid-coloured square with a dark icon (white on blue and red): the mark of a subject or row.
class SubjectIconTile extends StatelessWidget {
  const SubjectIconTile({super.key, required this.icon, required this.hue, this.size = 44, this.soft = false});

  /// The tile of a subject by id, in its stable colour.
  SubjectIconTile.forSubject(String subjectId, {Key? key, required IconData icon, double size = 44})
    : this(key: key, icon: icon, hue: subjectHue(subjectId), size: size);

  final IconData icon;
  final PlengoHue hue;

  /// 40–48.
  final double size;

  /// Soft background with the hue's ink icon instead of the solid fill.
  final bool soft;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft ? hue.soft : hue.fill,
        borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
      ),
      child: Icon(icon, size: size * 0.5, color: soft ? hue.ink : hue.onFill),
    ),
  );
}

/// A list row (spec §4): min 64, radius 20, icon tile, title 15/700, caption 12 mute, and a mirrored
/// chevron (or [trailing]). [flat] rows sit in grouped lists with a divider under each one.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.caption,
    this.icon,
    this.hue = PlengoColors.blue,
    this.leading,
    this.trailing,
    this.onTap,
    this.flat = false,
    this.showDivider = true,
    this.background,
    this.titleColor,
    this.semanticsLabel,
  });

  final String title;
  final String? caption;

  /// Builds a [SubjectIconTile] in [hue]; [leading] replaces it.
  final IconData? icon;
  final PlengoHue hue;
  final Widget? leading;

  /// Replaces the chevron (e.g. a chip). The chevron shows only when the row is tappable.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool flat;

  /// Flat rows only: the divider under the row.
  final bool showDivider;

  /// Overrides the card colour (e.g. a soft hue, whose text must then be dark ink).
  final Color? background;
  final Color? titleColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final onSoft = background != null;
    final ink = titleColor ?? (onSoft ? PlengoColors.ink : s.ink);
    final mute = onSoft ? PlengoColors.ink.withValues(alpha: 0.78) : s.mute;
    final lead = leading ?? (icon == null ? null : SubjectIconTile(icon: icon!, hue: hue));
    final end = trailing ?? (onTap == null ? null : Icon(Icons.chevron_right_rounded, color: onSoft ? ink : s.mute));
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: flat ? 56 : PlengoSpace.row),
      child: Padding(
        padding: flat
            ? const EdgeInsetsDirectional.symmetric(horizontal: 2, vertical: 10)
            : const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: PlengoType.rowTitle.copyWith(color: ink)),
                  if (caption != null) Text(caption!, style: PlengoType.caption.copyWith(color: mute)),
                ],
              ),
            ),
            if (end != null) ...[const SizedBox(width: 8), end],
          ],
        ),
      ),
    );
    final r = BorderRadius.circular(flat ? 0 : PlengoRadius.row);
    Widget body = Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: r, onTap: onTap, child: row),
    );
    if (flat) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: showDivider ? Border(bottom: BorderSide(color: s.line)) : null,
        ),
        child: body,
      );
    } else {
      body = DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? s.card,
          borderRadius: r,
          border: !onSoft && s.isDark ? Border.all(color: s.line) : null,
          boxShadow: onSoft || s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
        ),
        child: ClipRRect(borderRadius: r, child: body),
      );
    }
    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      container: true,
      child: MergeSemantics(child: body),
    );
  }
}

/// A section title (18/700, marked as a header) with an optional link-style action at the end.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.top = 20, this.bottom = 8});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: top, bottom: bottom),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: PlengoType.section.copyWith(color: s.ink)),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: s.action,
                textStyle: const TextStyle(fontFamily: PlengoType.family, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// 3–5 small circles in logo colours around a celebration icon. Decorative only (no semantics); they
/// scale in once (≤ 600 ms), or appear at once with reduced motion.
class ConfettiDots extends StatefulWidget {
  const ConfettiDots({super.key, required this.child, this.spread = 24, this.animate = true});

  final Widget child;

  /// How far outside [child] the dots sit.
  final double spread;
  final bool animate;

  @override
  State<ConfettiDots> createState() => _ConfettiDotsState();
}

class _ConfettiDotsState extends State<ConfettiDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: PlengoMotion.celebrate);

  // (angle in degrees from the top, clockwise; diameter; colour)
  static final _dots = [
    (-40.0, 22.0, PlengoColors.yellow.base),
    (35.0, 14.0, PlengoColors.pink.base),
    (110.0, 18.0, PlengoColors.green.base),
    (200.0, 12.0, PlengoColors.orange.base),
    (260.0, 26.0, PlengoColors.blue.base),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || PlengoMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Padding(padding: EdgeInsets.all(widget.spread), child: widget.child),
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, box) {
                  final cx = box.maxWidth / 2, cy = box.maxHeight / 2;
                  final rx = cx - widget.spread / 2, ry = cy - widget.spread / 2;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (i, (angle, d, color)) in _dots.indexed)
                        Positioned(
                          left: cx + rx * math.sin(angle * math.pi / 180) - d / 2,
                          top: cy - ry * math.cos(angle * math.pi / 180) - d / 2,
                          child: ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _c,
                              curve: Interval(i * 0.12, 0.52 + i * 0.12, curve: Curves.easeOutBack),
                            ),
                            child: Container(
                              width: d,
                              height: d,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
