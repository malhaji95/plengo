import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// A linear progress bar that always carries a text label (e.g. «السؤال 7 من 20»). Height 10, or 6
/// when [compact]. The fill animates over 300 ms (instant with reduced motion).
class PlengoProgressBar extends StatelessWidget {
  const PlengoProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.trackColor,
    this.labelColor,
    this.compact = false,
    this.labelBelow = false,
    this.semanticsLabel,
  });

  /// 0–1.
  final double value;

  /// Never empty: progress is never shown by colour alone.
  final String label;

  /// Fill; defaults to the action colour.
  final Color? color;

  /// Track; defaults to the skeleton/track colour (on the hero: white 30%).
  final Color? trackColor;
  final Color? labelColor;
  final bool compact;

  /// Label under the bar (app-bar headers) instead of after it.
  final bool labelBelow;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final height = compact ? 6.0 : 10.0;
    final bar = SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: PlengoMotion.of(context, PlengoMotion.progress),
        curve: Curves.easeOut,
        builder: (context, t, _) => CustomPaint(
          painter: _BarPainter(
            value: t,
            fill: color ?? s.action,
            track: trackColor ?? s.track,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
          size: Size.infinite,
        ),
      ),
    );
    final text = Text(
      label,
      style: PlengoType.chip.copyWith(color: labelColor ?? DefaultTextStyle.of(context).style.color ?? s.ink),
    );
    return Semantics(
      label: semanticsLabel ?? label,
      value: '${(v * 100).round()}%',
      excludeSemantics: true,
      child: labelBelow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [bar, const SizedBox(height: 4), text],
            )
          : Row(
              children: [
                Expanded(child: bar),
                const SizedBox(width: 10),
                Flexible(flex: 0, child: text),
              ],
            ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.value, required this.fill, required this.track, required this.rtl});

  final double value;
  final Color fill;
  final Color track;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    if (value <= 0) return;
    final w = math.max(size.height, size.width * value);
    final left = rtl ? size.width - w : 0.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, size.height), r), Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.value != value || old.fill != fill || old.track != track || old.rtl != rtl;
}

/// A circular progress with round caps and the value text in the centre (daily goal, completion).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 64,
    this.color,
    this.trackColor,
    this.strokeWidth,
    this.labelStyle,
    this.semanticsLabel,
  });

  /// 0–1.
  final double value;

  /// Centre text, e.g. «12/20» or «42%».
  final String label;
  final double size;

  /// Fill; defaults to green (daily goal).
  final Color? color;
  final Color? trackColor;

  /// 6–9; defaults to size / 10 within that range.
  final double? strokeWidth;
  final TextStyle? labelStyle;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final stroke = strokeWidth ?? (size / 10).clamp(6.0, 9.0);
    return Semantics(
      label: semanticsLabel ?? label,
      value: '${(v * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: PlengoMotion.of(context, PlengoMotion.progress),
          curve: Curves.easeOut,
          builder: (context, t, child) => CustomPaint(
            painter: _RingPainter(
              value: t,
              stroke: stroke,
              fill: color ?? PlengoColors.green.base,
              track: trackColor ?? s.track,
            ),
            child: child,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(stroke + 2),
              child: FittedBox(
                child: Text(
                  label,
                  style:
                      labelStyle ??
                      TextStyle(
                        fontFamily: PlengoType.family,
                        fontWeight: FontWeight.w700,
                        fontSize: size >= 70 ? 19 : (size >= 56 ? 15 : 11),
                        color: DefaultTextStyle.of(context).style.color ?? s.ink,
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.stroke, required this.fill, required this.track});

  final double value;
  final double stroke;
  final Color fill;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint..color = fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.stroke != stroke || old.fill != fill || old.track != track;
}
