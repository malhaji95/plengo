import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text('يرجى تحديث التطبيق', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('هذا الإصدار لم يعد مدعوماً. حدّث التطبيق للمتابعة.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (env.isWeb)
                  FilledButton.icon(
                    // Reloading the page loads the new build.
                    onPressed: () => launchUrl(Uri.base, webOnlyWindowName: '_self'),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تحميل الصفحة'),
                  )
                else if (store != null && store.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('تحديث من المتجر'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
