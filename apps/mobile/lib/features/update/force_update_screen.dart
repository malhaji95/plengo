import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/brand_logo.dart';

/// Blocking screen below `minSupportedVersion` (spec §10.2): a store link on Android/iOS (from
/// remote config `storeUrls`), a reload on web that fetches the new build.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvironmentProvider);
    final urls = ref.watch(remoteConfigProvider).value?.storeUrls;
    final store = switch (env.platform) {
      'android' => urls?.android,
      'ios' => urls?.ios,
      _ => null,
    };
    final s = context.surface;
    return Scaffold(
      backgroundColor: s.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(height: 40)),
                  const SizedBox(height: 28),
                  const Center(
                    child: ConfettiDots(
                      spread: 18,
                      child: StateIllustration(icon: Icons.system_update_rounded, hue: PlengoColors.blue),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      'يرجى تحديث التطبيق',
                      textAlign: TextAlign.center,
                      style: PlengoType.section.copyWith(fontSize: 22, color: s.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'هذا الإصدار لم يعد مدعوماً. حدّث التطبيق للمتابعة.',
                    textAlign: TextAlign.center,
                    style: PlengoType.sub.copyWith(color: s.mute),
                  ),
                  const SizedBox(height: 24),
                  if (env.isWeb)
                    PlengoButton(
                      // Reloading the page loads the new build.
                      onPressed: () => launchUrl(Uri.base, webOnlyWindowName: '_self'),
                      icon: Icons.refresh_rounded,
                      label: 'إعادة تحميل الصفحة',
                    )
                  else if (store != null && store.isNotEmpty)
                    PlengoButton(
                      onPressed: () => launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication),
                      icon: Icons.open_in_new_rounded,
                      label: 'تحديث من المتجر',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
