import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
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
      appBar: AppBar(title: const Text('الأجهزة المتصلة')),
      body: ContentWidth(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(sessionsProvider),
              child: Text(e is ApiException ? e.message : ApiException.genericMessage),
            ),
          ),
          data: (items) => ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              return ListTile(
                leading: Icon(s.platform == SessionPlatform.web ? Icons.language : Icons.phone_android),
                title: Text(_platformLabels[s.platform] ?? s.platform.name),
                subtitle: Text('آخر نشاط: ${format.format(s.lastSeenAt.toLocal())}'),
                trailing: s.current
                    ? const Chip(label: Text('هذا الجهاز'))
                    : TextButton(
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).revokeSession(s.id);
                          ref.invalidate(sessionsProvider);
                        },
                        child: const Text('إنهاء'),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
