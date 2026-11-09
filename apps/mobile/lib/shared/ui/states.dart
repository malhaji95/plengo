import 'package:flutter/material.dart';

import 'buttons.dart';
import 'tokens.dart';

/// The illustration of empty and error states: a large icon in a soft circle. Swap [child] for an
/// illustration later without touching the screens.
class StateIllustration extends StatelessWidget {
  const StateIllustration({super.key, required this.icon, this.hue = PlengoColors.yellow, this.size = 120, this.child});

  final IconData icon;
  final PlengoHue hue;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: hue.soft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child ?? Icon(icon, size: size * 0.44, color: hue.ink),
    ),
  );
}

/// Empty state (spec §4): 120 soft circle with an icon, title 18/700, one line of text, an optional
/// secondary button.
class PlengoEmptyState extends StatelessWidget {
  const PlengoEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.hue = PlengoColors.yellow,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  final String title;
  final String? message;
  final IconData icon;
  final PlengoHue hue;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateIllustration(icon: icon, hue: hue, child: illustration),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PlengoType.section.copyWith(color: s.ink),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: PlengoType.sub.copyWith(color: s.mute),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              PlengoButton(
                label: actionLabel!,
                variant: PlengoButtonVariant.secondary,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state (V-ErrorRetry): like the empty state, plus a primary «إعادة المحاولة» and an optional
/// offline escape link (e.g. «راجع المحتوى المحمّل»).
class PlengoErrorState extends StatelessWidget {
  const PlengoErrorState({
    super.key,
    required this.title,
    required this.onRetry,
    this.message,
    this.icon = Icons.wifi_off_rounded,
    this.hue = PlengoColors.orange,
    this.retryLabel = 'إعادة المحاولة',
    this.offlineLabel,
    this.onOffline,
  });

  final String title;
  final String? message;
  final IconData icon;
  final PlengoHue hue;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? offlineLabel;
  final VoidCallback? onOffline;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateIllustration(icon: icon, hue: hue),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: PlengoType.section.copyWith(color: s.ink),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: PlengoType.sub.copyWith(color: s.mute),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PlengoButton(label: retryLabel, icon: Icons.refresh_rounded, expand: false, onPressed: onRetry),
            if (offlineLabel != null) ...[
              const SizedBox(height: 4),
              PlengoButton(
                label: offlineLabel!,
                variant: PlengoButtonVariant.ghost,
                expand: false,
                onPressed: onOffline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A skeleton block in the track colour. Wrap a group of them in [SkeletonGroup] so screen readers
/// hear «جارٍ التحميل…» once.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 14, this.circle = false});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: circle ? height : width,
    height: height,
    decoration: BoxDecoration(
      color: context.surface.track,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

/// Skeleton blocks that mirror a layout, announced once as «جارٍ التحميل…».
class SkeletonGroup extends StatelessWidget {
  const SkeletonGroup({super.key, required this.child, this.label = loadingLabel});

  static const loadingLabel = 'جارٍ التحميل…';

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    container: true,
    child: ExcludeSemantics(child: child),
  );
}

/// A generic loading skeleton: a hero block, a card block and rows, top-aligned like real content.
class PlengoLoadingSkeleton extends StatelessWidget {
  const PlengoLoadingSkeleton({super.key, this.rows = 3, this.hero = true, this.padding});

  final int rows;
  final bool hero;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => SkeletonGroup(
    child: Padding(
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hero) ...[const Skeleton(height: 140, radius: PlengoRadius.hero), const SizedBox(height: 16)],
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: PlengoSpace.listGap),
            const Skeleton(height: PlengoSpace.row, radius: PlengoRadius.row),
          ],
        ],
      ),
    ),
  );
}
