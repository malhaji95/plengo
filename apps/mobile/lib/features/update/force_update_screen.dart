import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Blocking screen below `minSupportedVersion` (spec §10.2). Store links are added with the
/// store listings in Phase 13; on web a reload fetches the new build.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                if (kIsWeb) ...[const SizedBox(height: 24), const Text('أعد تحميل الصفحة للحصول على أحدث إصدار.')],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
