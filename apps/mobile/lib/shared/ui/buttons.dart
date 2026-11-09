import 'package:flutter/material.dart';

import 'tokens.dart';

enum PlengoButtonVariant {
  /// Blue (action colour) with a 3D shadow: the main action of a screen.
  primary,

  /// Yellow with a 3D shadow: celebration and "continue" moments.
  brand,

  /// Card background, 2 px action border, action text.
  secondary,

  /// Text only, action colour.
  ghost,

  /// Strong red `#C63B3B` with white text and a 3D shadow.
  danger,

  /// Green with dark text and a 3D shadow.
  success,
}

enum PlengoButtonSize {
  /// 54 high, radius 18, 16/700.
  regular,

  /// 48 high, radius 14, 14/700, no 3D shadow.
  small,
}

/// The redesign button (DESIGN_SPEC §4). A null [onPressed] draws the disabled style (track fill, mute
/// text, no shadow). Pressing moves it down 4 px and drops the shadow (100 ms; instant with reduced motion).
class PlengoButton extends StatefulWidget {
  const PlengoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PlengoButtonVariant.primary,
    this.size = PlengoButtonSize.regular,
    this.icon,
    this.busy = false,
    this.expand,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final PlengoButtonVariant variant;
  final PlengoButtonSize size;

  /// Leading icon (8 px before the label).
  final IconData? icon;

  /// Shows a spinner instead of the label and ignores taps, keeping the variant's colours.
  final bool busy;

  /// Full width; defaults to true for [PlengoButtonSize.regular] and false for small.
  final bool? expand;

  /// Spoken instead of [label].
  final String? semanticsLabel;

  bool get enabled => onPressed != null;

  @override
  State<PlengoButton> createState() => _PlengoButtonState();
}

class _PlengoButtonState extends State<PlengoButton> {
  bool _pressed = false;

  ({Color bg, Color fg, Color? shadow, Color? border}) _colors(PlengoSurface s) {
    if (!widget.enabled) return (bg: s.track, fg: s.mute, shadow: null, border: null);
    return switch (widget.variant) {
      PlengoButtonVariant.primary => (bg: s.action, fg: s.onAction, shadow: s.actionShadow, border: null),
      PlengoButtonVariant.brand => (
        bg: PlengoColors.yellow.base,
        fg: PlengoColors.ink,
        shadow: PlengoColors.yellow.shadow,
        border: null,
      ),
      PlengoButtonVariant.secondary => (bg: s.card, fg: s.action, shadow: null, border: s.action),
      PlengoButtonVariant.ghost => (bg: Colors.transparent, fg: s.action, shadow: null, border: null),
      PlengoButtonVariant.danger => (
        bg: PlengoColors.redStrong,
        fg: Colors.white,
        shadow: PlengoColors.red.shadow,
        border: null,
      ),
      PlengoButtonVariant.success => (
        bg: PlengoColors.green.base,
        fg: PlengoColors.ink,
        shadow: PlengoColors.green.shadow,
        border: null,
      ),
    };
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final small = widget.size == PlengoButtonSize.small;
    final c = _colors(s);
    final shadow = small ? null : c.shadow;
    final interactive = widget.enabled && !widget.busy;
    final pressed = _pressed && interactive && shadow != null;
    final radius = BorderRadius.circular(small ? PlengoRadius.buttonSmall : PlengoRadius.button);
    final minHeight = small ? PlengoSpace.buttonSmall : PlengoSpace.button;
    final textStyle = (small ? PlengoType.buttonSmall : PlengoType.button).copyWith(color: c.fg);
    final expand = widget.expand ?? !small;

    final label = widget.busy
        ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: c.fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(widget.label, textAlign: TextAlign.center, style: textStyle),
              ),
            ],
          );

    final button = AnimatedContainer(
      duration: PlengoMotion.of(context, PlengoMotion.press),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, pressed ? 4 : 0, 0),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: radius,
        border: c.border == null ? null : Border.all(color: c.border!, width: 2),
        boxShadow: shadow == null || pressed ? const [] : [BoxShadow(color: shadow, offset: const Offset(0, 4))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          onTap: interactive ? widget.onPressed : null,
          onHighlightChanged: _setPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight, minWidth: 48),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: small ? 16 : 20, vertical: 8),
              child: Center(widthFactor: expand ? null : 1, heightFactor: 1, child: label),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel ?? widget.label,
      excludeSemantics: true,
      onTap: interactive ? widget.onPressed : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// A 48 × 48 icon button; [soft] draws it on a card-coloured rounded square (app bars). [tooltip] is
/// also its spoken label, so icon-only buttons are never silent.
class PlengoIconButton extends StatelessWidget {
  const PlengoIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.soft = true,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool soft;
  final Color? color;

  /// A small count in the top corner (e.g. unread notifications); hidden when null or 0.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final radius = BorderRadius.circular(PlengoRadius.iconButton);
    final count = badge ?? 0;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: count > 0 ? '$tooltip، $count' : tooltip,
        excludeSemantics: true,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: PlengoSpace.minTouch,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: soft ? s.card : Colors.transparent,
                    borderRadius: radius,
                    border: soft && s.isDark ? Border.all(color: s.line) : null,
                    boxShadow: soft && !s.isDark ? [BoxShadow(color: s.line, offset: const Offset(0, 1))] : null,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: radius,
                      onTap: onPressed,
                      child: Icon(icon, size: 24, color: onPressed == null ? s.mute : (color ?? s.ink)),
                    ),
                  ),
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PlengoColors.redStrong,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: s.background, width: 2),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-bar back: a mirrored arrow in a 48 × 48 soft square (spec §5). Pops the route by default.
class PlengoBackButton extends StatelessWidget {
  const PlengoBackButton({super.key, this.onPressed, this.tooltip = 'رجوع'});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: Center(
      child: PlengoIconButton(
        // arrow_back follows the text direction: it points right in RTL.
        icon: Icons.arrow_back_rounded,
        tooltip: tooltip,
        onPressed: onPressed ?? () => Navigator.maybePop(context),
      ),
    ),
  );
}

/// ✕ for full-screen flows (question, exam, flashcard review, results). [onPressed] usually opens the
/// exit confirmation sheet; it never discards silently.
class PlengoCloseButton extends StatelessWidget {
  const PlengoCloseButton({super.key, this.onPressed, this.tooltip = 'خروج'});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: Center(
      child: PlengoIconButton(
        icon: Icons.close_rounded,
        tooltip: tooltip,
        onPressed: onPressed ?? () => Navigator.maybePop(context),
      ),
    ),
  );
}

/// The `leadingWidth` an [AppBar] needs for [PlengoBackButton] / [PlengoCloseButton].
const double kPlengoLeadingWidth = 64;
