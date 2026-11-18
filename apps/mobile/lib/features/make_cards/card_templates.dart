import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/ui/ui.dart';
import '../../shared/widgets/optional_asset.dart';

/// A frame the student's own cards are drawn on (v3 §7). The owner's frames are PNGs dropped into
/// `assets/templates/<key>.png` (A4 portrait, 1241 × 1754); they are offered only when bundled. The
/// four built-in frames are drawn in code from the brand shapes.
@immutable
class CardTemplate {
  const CardTemplate(this.key, this.nameAr, this.hue, {this.asset = false});

  /// Stored on the deck (`templateKey`, `^[a-z0-9][a-z0-9_-]{0,39}$`).
  final String key;
  final String nameAr;
  final PlengoHue hue;

  /// The frame is the owner's PNG at [assetPath].
  final bool asset;

  String get assetPath => 'assets/templates/$key.png';

  @override
  String toString() => 'CardTemplate($key)';
}

abstract final class CardTemplates {
  static const physics = CardTemplate('physics', 'فيزياء', PlengoColors.blue, asset: true);
  static const medical = CardTemplate('medical', 'طبي', PlengoColors.green, asset: true);
  static const grid = CardTemplate('grid', 'مربّعات', PlengoColors.blue);
  static const sun = CardTemplate('sun', 'شمس', PlengoColors.yellow);
  static const clouds = CardTemplate('clouds', 'غيوم', PlengoColors.green);
  static const stars = CardTemplate('stars', 'نجوم', PlengoColors.pink);

  /// The owner's frames (shown only when bundled).
  static const owner = [physics, medical];

  /// The frames drawn in code (always offered).
  static const drawn = [grid, sun, clouds, stars];

  static const all = [...owner, ...drawn];

  /// The template stored as [key]; unknown keys (a frame from a newer app) fall back to [grid].
  static CardTemplate? of(String? key) =>
      key == null ? null : all.where((t) => t.key == key).firstOrNull ?? CardTemplates.grid;
}

/// The frames this build can offer: the owner's PNGs that are bundled, then the drawn ones.
List<CardTemplate> availableTemplates(WidgetRef ref) => [
  for (final t in CardTemplates.owner)
    if (assetBundled(ref, t.assetPath)) t,
  ...CardTemplates.drawn,
];

/// A card's content on its template frame: the frame's tinted paper, its decoration around the edge,
/// and [child] inside the margin. In dark mode the paper is the dark card tinted with the hue, so the
/// card's text keeps its contrast. Decorative only: the frame adds nothing for screen readers.
class TemplateFrame extends ConsumerWidget {
  const TemplateFrame({super.key, required this.templateKey, required this.child, this.compact = false});

  final String templateKey;
  final Widget child;

  /// A small preview (template picker, lists): thinner margins.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = CardTemplates.of(templateKey)!;
    final s = context.surface;
    final margin = EdgeInsets.all(compact ? 14 : 30);
    if (t.asset && assetBundled(ref, t.assetPath)) {
      return Stack(
        key: Key('template.${t.key}'),
        children: [
          Positioned.fill(child: Image.asset(t.assetPath, fit: BoxFit.fill, excludeFromSemantics: true)),
          Padding(padding: margin, child: child),
        ],
      );
    }
    final drawn = t.asset ? CardTemplates.grid : t;
    final paper = s.isDark
        ? Color.alphaBlend(drawn.hue.base.withValues(alpha: 0.10), s.card)
        : Color.alphaBlend(drawn.hue.soft.withValues(alpha: 0.7), s.card);
    return CustomPaint(
      key: Key('template.${t.key}'),
      painter: TemplatePainter(drawn, paper: paper, dark: s.isDark, compact: compact),
      child: Padding(padding: margin, child: child),
    );
  }
}

/// Draws one of the built-in frames.
class TemplatePainter extends CustomPainter {
  TemplatePainter(this.template, {required this.paper, required this.dark, this.compact = false});

  final CardTemplate template;
  final Color paper;
  final bool dark;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final hue = template.hue;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = paper);
    final unit = compact ? 0.5 : 1.0;
    final inset = 8.0 * unit;
    final border = RRect.fromRectAndRadius(rect.deflate(inset), Radius.circular(18 * unit));
    switch (template.key) {
      case 'grid':
        final line = Paint()
          ..color = hue.base.withValues(alpha: dark ? 0.22 : 0.20)
          ..strokeWidth = 1;
        final step = 18.0 * unit;
        canvas.save();
        canvas.clipRRect(border);
        for (var x = border.left + step; x < border.right; x += step) {
          canvas.drawLine(Offset(x, border.top), Offset(x, border.bottom), line);
        }
        for (var y = border.top + step; y < border.bottom; y += step) {
          canvas.drawLine(Offset(border.left, y), Offset(border.right, y), line);
        }
        canvas.restore();
      case 'sun':
        final c = Offset(border.left + 30 * unit, border.top + 30 * unit);
        final sun = Paint()..color = hue.base;
        canvas.drawCircle(c, 13 * unit, sun);
        final ray = Paint()
          ..color = PlengoColors.orange.base
          ..strokeWidth = 3 * unit
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(c + d * (18 * unit), c + d * (25 * unit), ray);
        }
        // A soft hill along the bottom edge.
        final hill = Path()
          ..moveTo(border.left, border.bottom - 18 * unit)
          ..quadraticBezierTo(size.width * 0.3, border.bottom - 42 * unit, size.width * 0.62, border.bottom - 16 * unit)
          ..quadraticBezierTo(size.width * 0.82, border.bottom - 4 * unit, border.right, border.bottom - 22 * unit)
          ..lineTo(border.right, border.bottom)
          ..lineTo(border.left, border.bottom)
          ..close();
        canvas.save();
        canvas.clipRRect(border);
        canvas.drawPath(hill, Paint()..color = hue.base.withValues(alpha: 0.35));
        canvas.restore();
      case 'clouds':
        final cloud = Paint()..color = (dark ? hue.base : Colors.white).withValues(alpha: dark ? 0.25 : 0.95);
        final edge = Paint()
          ..color = hue.base.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * unit;
        void puff(Offset at, double r) {
          final p = Path()
            ..addOval(Rect.fromCircle(center: at, radius: r))
            ..addOval(Rect.fromCircle(center: at + Offset(r * 0.9, r * 0.25), radius: r * 0.75))
            ..addOval(Rect.fromCircle(center: at + Offset(-r * 0.9, r * 0.3), radius: r * 0.7));
          canvas.drawPath(p, cloud);
          canvas.drawPath(p, edge);
        }

        puff(Offset(border.right - 34 * unit, border.top + 22 * unit), 12 * unit);
        puff(Offset(border.left + 34 * unit, border.bottom - 20 * unit), 13 * unit);
        puff(Offset(border.right - 52 * unit, border.bottom - 16 * unit), 9 * unit);
      case 'stars':
        void star(Offset c, double r, Color color) {
          final p = Path();
          for (var i = 0; i < 10; i++) {
            final a = -math.pi / 2 + i * math.pi / 5;
            final rr = i.isEven ? r : r * 0.45;
            final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
            i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(p..close(), Paint()..color = color);
        }

        star(Offset(border.left + 24 * unit, border.top + 24 * unit), 10 * unit, PlengoColors.yellow.base);
        star(Offset(border.right - 26 * unit, border.top + 34 * unit), 7 * unit, hue.base);
        star(Offset(border.right - 24 * unit, border.bottom - 24 * unit), 10 * unit, PlengoColors.yellow.base);
        star(Offset(border.left + 30 * unit, border.bottom - 30 * unit), 6 * unit, hue.base);
        final dot = Paint()..color = PlengoColors.blue.base.withValues(alpha: 0.6);
        canvas.drawCircle(Offset(border.left + 48 * unit, border.top + 16 * unit), 3 * unit, dot);
        canvas.drawCircle(Offset(border.right - 46 * unit, border.bottom - 14 * unit), 3 * unit, dot);
    }
    canvas.drawRRect(
      border,
      Paint()
        ..color = hue.base
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * unit,
    );
  }

  @override
  bool shouldRepaint(TemplatePainter old) =>
      old.template != template || old.paper != paper || old.dark != dark || old.compact != compact;
}
