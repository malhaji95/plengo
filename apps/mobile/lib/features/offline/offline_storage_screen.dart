import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../shared/widgets/async_view.dart';
import 'offline_providers.dart';

/// Download settings and "المساحة المستخدمة" (spec §22.2): every pack with its size, last update
/// and a delete button.
class OfflineStorageScreen extends ConsumerStatefulWidget {
  const OfflineStorageScreen({super.key});

  @override
  ConsumerState<OfflineStorageScreen> createState() => _OfflineStorageScreenState();
}

class _OfflineStorageScreenState extends ConsumerState<OfflineStorageScreen> {
  bool? _wifiOnly;
  bool? _autoUpdate;

  @override
  void initState() {
    super.initState();
    final store = ref.read(packStoreProvider);
    store.wifiOnly().then((v) => mounted ? setState(() => _wifiOnly = v) : null);
    store.autoUpdate().then((v) => mounted ? setState(() => _autoUpdate = v) : null);
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(const Duration(hours: 3));
    return '${d.year}/${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(packsProvider);
    final store = ref.read(packStoreProvider);
    final ctl = ref.read(offlineControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('المحتوى المحمّل')),
      body: AsyncView(
        value: packs,
        onRetry: () => ref.invalidate(packsProvider),
        data: (list) {
          final groups = <String, List<OfflinePackRow>>{};
          for (final p in list) {
            groups.putIfAbsent(p.scopeTitle, () => []).add(p);
          }
          final total = list.where((p) => p.status == 'ready').fold(0, (s, p) => s + p.sizeBytes);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  SwitchListTile(
                    title: const Text('التحميل عبر Wi-Fi فقط'),
                    value: _wifiOnly ?? true,
                    onChanged: (v) async {
                      setState(() => _wifiOnly = v);
                      await store.setWifiOnly(v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تحديث المحتوى المحمّل تلقائياً'),
                    value: _autoUpdate ?? true,
                    onChanged: (v) async {
                      setState(() => _autoUpdate = v);
                      await store.setAutoUpdate(v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('المساحة المستخدمة'),
                    trailing: Text(formatBytes(total), textDirection: TextDirection.rtl),
                  ),
                  if (list.isEmpty)
                    const EmptyState(
                      'لم تحمّل أي محتوى بعد. استخدم أزرار التحميل في صفحات المواد والوحدات والبطاقات.',
                      icon: Icons.download_for_offline_outlined,
                    ),
                  for (final MapEntry(key: title, value: rows) in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    for (final p in rows)
                      ListTile(
                        title: Text(p.titleAr),
                        subtitle: Text(
                          [
                            formatBytes(p.sizeBytes),
                            switch (p.status) {
                              'ready' when p.remoteVersion != null && p.remoteVersion != p.version => 'تحديث متاح',
                              'ready' => 'آخر تحديث ${_date(p.updatedAt)}',
                              'downloading' || 'queued' => 'جارٍ التحميل',
                              'waiting_wifi' => 'بانتظار Wi-Fi',
                              'paused' => 'متوقف مؤقتاً',
                              _ => 'تعذّر التحميل',
                            },
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ctl.cancel(p.packKey),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
