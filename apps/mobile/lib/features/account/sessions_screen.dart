import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';

final sessionsProvider = FutureProvider.autoDispose<List<SessionSummary>>(
  (ref) => ref.watch(authRepositoryProvider).sessions(),
);

/// Students can see and revoke their sessions (spec §11.2). No device limit (§0.8).
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  static const _platformLabels = {
    SessionPlatform.android: 'أندرويد',
    SessionPlatform.ios: 'آيفون',
    SessionPlatform.web: 'متصفح الويب',
    SessionPlatform.admin: 'لوحة الإدارة',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final format = DateFormat('yyyy/MM/dd – HH:mm', 'ar');
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('الأجهزة المتصلة'),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: sessions,
          onRetry: () => ref.invalidate(sessionsProvider),
          data: (items) => ListView.separated(
            padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: PlengoSpace.listGap),
            itemBuilder: (context, i) {
              final s = items[i];
              return ListRow(
                icon: s.platform == SessionPlatform.web ? Icons.language_rounded : Icons.phone_android_rounded,
                hue: s.current ? PlengoColors.blue : PlengoColors.yellow,
                title: _platformLabels[s.platform] ?? s.platform.name,
                caption: 'آخر نشاط: ${format.format(s.lastSeenAt.toLocal())}',
                trailing: s.current
                    ? const PlengoChip(label: 'هذا الجهاز', icon: Icons.check_rounded)
                    : PlengoButton(
                        label: 'إنهاء',
                        variant: PlengoButtonVariant.secondary,
                        size: PlengoButtonSize.small,
                        semanticsLabel: 'إنهاء الجلسة على ${_platformLabels[s.platform] ?? s.platform.name}',
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).revokeSession(s.id);
                          ref.invalidate(sessionsProvider);
                        },
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
