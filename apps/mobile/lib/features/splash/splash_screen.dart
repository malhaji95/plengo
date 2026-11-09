import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/brand_logo.dart';

/// V-Splash: full yellow, the colour logo (240 wide) and a small dark loader while the session
/// restores. A failed restore shows the error with «إعادة المحاولة». Deep links wait in the router's
/// `?from=` and open once the session is back.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    // Same yellow as the native launch screen, so start-up is one continuous brand moment.
    return Scaffold(
      backgroundColor: PlengoColors.yellow.base,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 240 wide: the wordmark is 960 × 348.
                const BrandLogo(height: 87, onBrand: true),
                const SizedBox(height: 40),
                if (auth.hasError) ...[
                  Text(
                    auth.error is ApiException ? (auth.error! as ApiException).message : ApiException.genericMessage,
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
    );
  }
}
