import 'package:flutter/material.dart';

import 'tokens.dart';

/// One choice of a [PillSelector] or [SegmentedControl].
@immutable
class PlengoOption<T> {
  const PlengoOption(this.value, this.label, {this.icon, this.child, this.semanticsLabel});

  final T value;
  final String label;
  final IconData? icon;

  /// Replaces the label text (e.g. font-size labels drawn at their own size); [label] is still spoken.
  final Widget? child;
  final String? semanticsLabel;
}

/// Horizontally scrolling pills (stage, subject, result and saved filters). 44 high, radius 99.
/// Selected: ink fill + white bold text (dark mode: yellow fill + dark text).
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
  });

  final List<PlengoOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Inside the scroll view, so the first pill lines up with the screen padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final (i, o) in options.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            PlengoPill(
              label: o.label,
              icon: o.icon,
              selected: o.value == selected,
              semanticsLabel: o.semanticsLabel,
              onTap: () => onSelected(o.value),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single selectable pill (see [PillSelector]).
class PlengoPill extends StatelessWidget {
  const PlengoPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.semanticsLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final bg = selected ? (s.isDark ? PlengoColors.yellow.base : PlengoColors.ink) : s.card;
    final fg = selected ? (s.isDark ? PlengoColors.ink : Colors.white) : s.ink;
    final border = selected ? bg : s.line;
    final r = BorderRadius.circular(PlengoRadius.pill);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      onTap: onTap,
      // The pill is drawn 44 high (plus its border); the touch target around it is 48 (brief §1.5).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            heightFactor: 1,
            child: AnimatedContainer(
              duration: PlengoMotion.of(context, PlengoMotion.press),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: r,
                border: Border.all(color: border, width: 1.5),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: r,
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: PlengoType.family,
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control (appearance, active/mastered): track background with 4 padding; the selected
/// segment is card-coloured with a light shadow and bold ink text.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({super.key, required this.segments, required this.selected, required this.onChanged});

  final List<PlengoOption<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: s.track, borderRadius: BorderRadius.circular(PlengoRadius.iconButton)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, seg) in segments.indexed) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _Segment(option: seg, selected: seg.value == selected, onChanged: onChanged),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({required this.option, required this.selected, required this.onChanged});

  final PlengoOption<T> option;
  final bool selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(12);
    final fg = selected ? s.ink : s.mute;
    final tap = onChanged == null ? null : () => onChanged!(option.value);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: option.semanticsLabel ?? option.label,
      excludeSemantics: true,
      onTap: tap,
      child: AnimatedContainer(
        duration: PlengoMotion.of(context, PlengoMotion.press),
        decoration: BoxDecoration(
          color: selected ? s.card : Colors.transparent,
          borderRadius: r,
          boxShadow: selected ? const [BoxShadow(color: Color(0x1F000000), offset: Offset(0, 1), blurRadius: 3)] : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: tap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontFamily: PlengoType.family,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                    textAlign: TextAlign.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.icon != null) ...[Icon(option.icon, size: 18, color: fg), const SizedBox(width: 6)],
                        Flexible(child: option.child ?? Text(option.label)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A radio row (goal list, report reasons, quiz mode): min 60, 2 px border. Selected: blue border,
/// blue-soft background, filled dot.
class RadioRow extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.caption,
    this.trailing,
    this.minHeight = 60,
  });

  final String title;
  final String? caption;
  final bool selected;
  final VoidCallback? onTap;

  /// E.g. «20 عنصراً · ~10 د».
  final Widget? trailing;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final blue = PlengoColors.blue;
    final r = BorderRadius.circular(PlengoRadius.option);
    // A selected row sits on the soft blue in both themes, so its text is dark ink.
    final ink = selected ? PlengoColors.ink : s.ink;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: MergeSemantics(
        child: AnimatedContainer(
          duration: PlengoMotion.of(context, PlengoMotion.press),
          decoration: BoxDecoration(
            color: selected ? blue.soft : s.card,
            borderRadius: r,
            border: Border.all(color: selected ? blue.base : s.line, width: 2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: r,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      _Dot(selected: selected),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: PlengoType.family,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            if (caption != null)
                              Text(caption!, style: PlengoType.caption.copyWith(color: selected ? blue.ink : s.mute)),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        DefaultTextStyle.merge(
                          style: PlengoType.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected ? blue.ink : s.mute,
                          ),
                          child: trailing!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final blue = PlengoColors.blue.base;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? blue : const Color(0xFF9A958B), width: 2),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: blue, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
