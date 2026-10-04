import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// An icon on a pale rounded square: the leading mark of cards and list rows.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.tint, this.color, this.size = 44});

  final IconData icon;

  /// Background; defaults to the pale brand blue.
  final Color? tint;

  /// Icon colour; defaults to ink on light tints.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = tint ?? BrandColors.tintBlue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? bg.withValues(alpha: 0.18) : bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? (dark ? bg : BrandColors.ink)),
    );
  }
}

/// A tappable card row: badge, title, optional subtitle, and a forward chevron (left in RTL).
class NavCard extends StatelessWidget {
  const NavCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.tint,
    this.trailing,
    this.onTap,
    this.margin,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? tint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: IconBadge(icon, tint: tint),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_left)),
        onTap: onTap,
      ),
    );
  }
}

/// A section title with an optional action on the far side.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.top = 20});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// A circular percentage, used for completion and the daily goal.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.label, this.size = 64, this.color});

  /// 0–1.
  final double value;
  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: value.clamp(0, 1).toDouble(),
              strokeWidth: size / 10,
              strokeCap: StrokeCap.round,
              color: color ?? BrandColors.success(Theme.of(context).brightness),
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          FittedBox(
            child: Padding(
              padding: EdgeInsets.all(size / 6),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bright brand tile with ink text (subject cards). [index] picks the colour from
/// [BrandColors.tiles] so neighbouring tiles differ.
class BrandTile extends StatelessWidget {
  const BrandTile({
    super.key,
    required this.index,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
    this.width = 148,
  });

  final int index;
  final IconData icon;
  final String title;
  final String? subtitle;

  /// A small marker in the top corner (for example a lock or "مجاني").
  final Widget? badge;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final fill = BrandColors.tiles[index % BrandColors.tiles.length];
    const ink = BrandColors.ink;
    return SizedBox(
      width: width,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: ink, size: 22),
                    ),
                    const Spacer(),
                    ?badge,
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ink, fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A large icon in a soft circle, the illustration of empty, error and onboarding moments.
class SpotIcon extends StatelessWidget {
  const SpotIcon(this.icon, {super.key, this.tint = BrandColors.tintBlue, this.color, this.size = 96});

  final IconData icon;
  final Color tint;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: dark ? tint.withValues(alpha: 0.16) : tint, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.46, color: color ?? (dark ? tint : BrandColors.action)),
    );
  }
}
