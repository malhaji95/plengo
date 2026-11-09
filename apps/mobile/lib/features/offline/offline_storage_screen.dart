import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
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

  /// Status as text + icon + hue (never colour alone).
  ({String label, IconData icon, PlengoHue hue}) _status(OfflinePackRow p) => switch (p.status) {
    'ready' when p.remoteVersion != null && p.remoteVersion != p.version => (
      label: 'تحديث متاح',
      icon: Icons.update_rounded,
      hue: PlengoColors.yellow,
    ),
    'ready' => (label: 'آخر تحديث ${_date(p.updatedAt)}', icon: Icons.offline_pin_rounded, hue: PlengoColors.blue),
    'downloading' || 'queued' => (label: 'جارٍ التحميل', icon: Icons.downloading_rounded, hue: PlengoColors.blue),
    'waiting_wifi' => (label: 'بانتظار Wi-Fi', icon: Icons.wifi_rounded, hue: PlengoColors.orange),
    'paused' => (label: 'متوقف مؤقتاً', icon: Icons.pause_circle_rounded, hue: PlengoColors.orange),
    _ => (label: 'تعذّر التحميل', icon: Icons.error_rounded, hue: PlengoColors.red),
  };

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final packs = ref.watch(packsProvider);
    final store = ref.read(packStoreProvider);
    final ctl = ref.read(offlineControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('المحتوى المحمّل'),
      ),
      body: AsyncView(
        value: packs,
        onRetry: () => ref.invalidate(packsProvider),
        data: (list) {
          final groups = <String, List<OfflinePackRow>>{};
          for (final p in list) {
            groups.putIfAbsent(p.scopeTitle, () => []).add(p);
          }
          final total = list.where((p) => p.status == 'ready').fold(0, (s, p) => s + p.sizeBytes);
          Widget toggle(String title, bool value, ValueChanged<bool> onChanged) => Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
              title: Text(title, style: PlengoType.rowTitle.copyWith(color: s.ink)),
              value: value,
              onChanged: onChanged,
            ),
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
                children: [
                  PlengoCard(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        toggle('التحميل عبر Wi-Fi فقط', _wifiOnly ?? true, (v) async {
                          setState(() => _wifiOnly = v);
                          await store.setWifiOnly(v);
                        }),
                        Divider(height: 1, color: s.line),
                        toggle('تحديث المحتوى المحمّل تلقائياً', _autoUpdate ?? true, (v) async {
                          setState(() => _autoUpdate = v);
                          await store.setAutoUpdate(v);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: PlengoSpace.section),
                  PlengoCard(
                    color: PlengoColors.blue.soft,
                    child: Row(
                      children: [
                        const SubjectIconTile(icon: Icons.sd_storage_rounded, hue: PlengoColors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'المساحة المستخدمة',
                            style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink),
                          ),
                        ),
                        Text(
                          formatBytes(total),
                          textDirection: TextDirection.rtl,
                          style: PlengoType.rowTitle.copyWith(color: PlengoColors.blue.ink),
                        ),
                      ],
                    ),
                  ),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(top: 24),
                      child: EmptyState(
                        'لم تحمّل أي محتوى بعد. استخدم أزرار التحميل في صفحات المواد والوحدات والبطاقات.',
                        icon: Icons.download_for_offline_outlined,
                      ),
                    ),
                  for (final MapEntry(key: title, value: rows) in groups.entries) ...[
                    SectionHeader(title),
                    PlengoCard(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 4),
                      child: Column(
                        children: [
                          for (final (i, p) in rows.indexed)
                            Builder(
                              builder: (context) {
                                final st = _status(p);
                                return ListRow(
                                  flat: true,
                                  showDivider: i < rows.length - 1,
                                  leading: SubjectIconTile(icon: st.icon, hue: st.hue, size: 40, soft: true),
                                  title: p.titleAr,
                                  caption: '${formatBytes(p.sizeBytes)} · ${st.label}',
                                  trailing: PlengoIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    tooltip: 'حذف',
                                    soft: false,
                                    color: s.isDark ? PlengoColors.red.base : PlengoColors.red.ink,
                                    onPressed: () => ctl.cancel(p.packKey),
                                  ),
                                );
                              },
                            ),
                        ],
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
