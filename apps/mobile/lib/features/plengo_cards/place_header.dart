import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/ui/ui.dart';
import '../../shared/widgets/optional_asset.dart';

/// The soft header at the top of the card places (v3 §6, §7): the owner's art from [assetPath] when it
/// is bundled (1080 × 420), else a drawn one: a soft panel with the title, the subtitle and a stack of
/// three tilted cards with [icon]. The title is the page's header for screen readers either way.
class PlaceHeader extends ConsumerWidget {
  const PlaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.hue = PlengoColors.blue,
    this.assetPath,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final PlengoHue hue;
  final String? assetPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = assetPath;
    if (path == null || !assetBundled(ref, path)) {
      return _Drawn(title: title, subtitle: subtitle, icon: icon, hue: hue);
    }
    // The art carries the title as pixels: keep it readable for screen readers.
    return Semantics(
      header: true,
      label: title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PlengoRadius.hero),
        child: AspectRatio(
          aspectRatio: 1080 / 420,
          child: Image.asset(path, fit: BoxFit.cover, excludeFromSemantics: true),
        ),
      ),
    );
  }
}

class _Drawn extends StatelessWidget {
  const _Drawn({required this.title, required this.subtitle, required this.icon, required this.hue});

  final String title;
  final String subtitle;
  final IconData icon;
  final PlengoHue hue;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final bg = s.isDark ? Color.alphaBlend(hue.base.withValues(alpha: 0.14), s.card) : hue.soft;
    return Container(
      key: const Key('placeHeader.drawn'),
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 12, 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(PlengoRadius.hero)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: PlengoType.title.copyWith(fontSize: 22, color: s.ink)),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: PlengoType.sub.copyWith(color: s.isDark ? s.mute : hue.ink)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ExcludeSemantics(child: CardStackArt(icon: icon, hue: hue)),
        ],
      ),
    );
  }
}

/// Three tilted cards with [icon] on the top one, and two confetti dashes (brand shapes).
class CardStackArt extends StatelessWidget {
  const CardStackArt({super.key, required this.icon, this.hue = PlengoColors.blue, this.size = 84});

  final IconData icon;
  final PlengoHue hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget card(double angle, Color color, {Widget? child}) => Transform.rotate(
      angle: angle,
      child: Container(
        width: size * 0.62,
        height: size * 0.78,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.12),
          border: Border.all(color: hue.base, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3))],
        ),
        child: child,
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          card(-0.28, PlengoColors.yellow.soft),
          card(0.16, PlengoColors.pink.soft),
          card(
            -0.04,
            Colors.white,
            child: Icon(icon, color: hue.base, size: size * 0.34),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 5,
                height: 14,
                decoration: BoxDecoration(
                  color: PlengoColors.yellow.base,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 10,
            end: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: PlengoColors.orange.base, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
