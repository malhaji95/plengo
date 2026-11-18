import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/optional_asset.dart';

/// The owner's splash video slot (V3_PLAN §1: 1080 × 1920, ≤ 3 s, H.264 MP4 ≤ 1.5 MB).
const splashVideoAsset = 'assets/brand/splash_motion.mp4';

/// The slogan under the logo (V3-Splash).
const splashSlogan = 'صديقك لمراجعة أسرع وأمتع';

/// Builds the player for [splashVideoAsset] when the file is bundled; null keeps the code-driven
/// motion.
///
/// TODO(v3-splash-video): when the owner sends `splash_motion.mp4`, add a light video player
/// (e.g. `video_player`), drop the file into `assets/brand/` and override this provider in `main` with
/// a builder that plays it once, muted, `BoxFit.cover`. No video dependency is added until then.
final splashVideoBuilderProvider = Provider<Widget Function(BuildContext context)?>((ref) => null);

/// V3-Splash: full yellow, the BLUE wordmark, a short motion intro (logo scale + fade and confetti
/// dots, ≤ 1.5 s; none with reduced motion) and the slogan «صديقك لمراجعة أسرع وأمتع», with a small
/// dark loader while the session restores. With the owner's video bundled (and a player wired in
/// [splashVideoBuilderProvider]) the video plays instead of the code motion. A failed restore shows the
/// error with «إعادة المحاولة». Deep links wait in the router's `?from=` and open once the session is
/// back.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final video = ref.watch(splashVideoBuilderProvider);
    final hasVideo = video != null && assetBundled(ref, splashVideoAsset);
    // Same yellow as the native launch screen, so start-up is one continuous brand moment.
    return Scaffold(
      backgroundColor: PlengoColors.yellow.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo) Positioned.fill(child: ExcludeSemantics(child: video(context))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hasVideo) const SplashMotion(),
                    const SizedBox(height: 20),
                    Text(
                      splashSlogan,
                      key: const Key('splash.slogan'),
                      textAlign: TextAlign.center,
                      style: PlengoType.section.copyWith(color: PlengoColors.ink),
                    ),
                    const SizedBox(height: 32),
                    if (auth.hasError) ...[
                      Text(
                        auth.error is ApiException
                            ? (auth.error! as ApiException).message
                            : ApiException.genericMessage,
                        textAlign: TextAlign.center,
                        style: PlengoType.body.copyWith(color: PlengoColors.ink, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      PlengoButton(
                        label: 'إعادة المحاولة',
                        icon: Icons.refresh_rounded,
                        expand: false,
                        onPressed: () => ref.read(authControllerProvider.notifier).retry(),
                      ),
                    ] else
                      Semantics(
                        label: 'جارٍ التحميل',
                        liveRegion: true,
                        child: const SizedBox.square(
                          dimension: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: PlengoColors.ink,
                            backgroundColor: Color(0x261B1B1B),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The code-driven intro: the blue wordmark scales up from 80 % and fades in over [duration] while
/// confetti dots pop around it. Reduced motion shows the final frame at once.
class SplashMotion extends StatefulWidget {
  const SplashMotion({super.key});

  /// The whole intro (the dots finish within [PlengoMotion.celebrate]).
  static const duration = Duration(milliseconds: 1200);

  @override
  State<SplashMotion> createState() => _SplashMotionState();
}

class _SplashMotionState extends State<SplashMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: SplashMotion.duration);
  late final _curve = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );
  late final _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.45, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PlengoMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _fade.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PlengoMotion.reduced(context);
    return ConfettiDots(
      spread: 28,
      animate: !reduced,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(_curve),
          // 240 wide: the wordmark is 960 × 348. Blue on yellow (V3-Splash).
          child: Semantics(
            label: 'Plengo',
            image: true,
            child: ExcludeSemantics(
              child: Image.asset('assets/brand/wordmark-blue.png', height: 87, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
