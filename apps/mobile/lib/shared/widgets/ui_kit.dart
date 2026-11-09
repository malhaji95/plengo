import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../ui/tokens.dart';

// The redesign's section header and progress ring replace the older ones under the same names.
export '../ui/progress.dart' show ProgressRing;
export '../ui/surfaces.dart' show SectionHeader;

/// An icon on a soft rounded square: the leading mark of cards and list rows. New code uses
/// `SubjectIconTile` from `shared/ui`.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.tint, this.color, this.size = 44});

  final IconData icon;

  /// Background; defaults to the soft brand blue.
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
        borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? (dark ? bg : BrandColors.ink)),
    );
  }
}

/// A tappable card row: badge, title, optional subtitle, and a forward chevron (pointing left in RTL).
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
    final s = context.surface;
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: IconBadge(icon, tint: tint),
        title: Text(title, style: PlengoType.rowTitle.copyWith(color: s.ink)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        // chevron_right follows the text direction: it points left (forward) in RTL.
        trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right_rounded, color: s.mute)),
        onTap: onTap,
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
        borderRadius: BorderRadius.circular(22),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
                      ),
                      child: Icon(icon, color: ink, size: 22),
                    ),
                    const Spacer(),
                    ?badge,
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PlengoType.rowTitle.copyWith(color: ink),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.caption.copyWith(color: ink),
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
