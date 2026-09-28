import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/db/app_database.dart';
import 'offline_providers.dart';

/// The app theme makes buttons full width; in a tile's trailing slot they must stay compact.
const _compact = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 40)));

/// Download control for a deck ("تحميل البطاقات"), a unit ("تحميل الوحدة") or a whole subject or
/// track ("تحميل الكل") (spec §22.1–§22.2): shows the size first, then progress with pause and
/// cancel, "تحديث متاح" when the server has a newer version, and "محمّل" when done.
class OfflineDownloadTile extends ConsumerWidget {
  const OfflineDownloadTile({super.key, required this.scope, required this.label, this.unitId, this.deckId});

  final ScopeQuery scope;
  final String label;
  final String? unitId;
  final String? deckId;

  List<OfflinePack> _pick(OfflineScopeCatalog c) => c.packs.where((p) {
    if (deckId != null) return p.kind == OfflinePackKind.deck && p.deckId == deckId;
    if (p.kind == OfflinePackKind.deck) return false;
    return unitId == null || p.unitId == unitId;
  }).toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(offlinePacksAvailableProvider)) return const SizedBox.shrink();
    final catalog = ref.watch(offlineScopeCatalogProvider(scope)).value;
    final rows = ref.watch(packsProvider).value ?? const <OfflinePackRow>[];
    final ctl = ref.read(offlineControllerProvider.notifier);
    final remote = catalog == null ? const <OfflinePack>[] : _pick(catalog);
    final keys = {for (final p in remote) p.packKey};
    final local = rows.where((r) {
      if (keys.contains(r.packKey)) return true;
      // Offline: no catalog; show what is on the device.
      if (catalog != null) return false;
      final sameScope = r.subjectId == scope.subjectId || r.teacherTrackId == scope.teacherTrackId;
      if (!sameScope) return false;
      if (deckId != null) return r.deckId == deckId && r.kind == 'deck';
      return r.kind != 'deck' && (unitId == null || r.unitId == unitId);
    }).toList();
    if (remote.isEmpty && local.isEmpty) return const SizedBox.shrink();

    final size = remote.isNotEmpty
        ? remote.fold(0, (s, p) => s + p.sizeBytes)
        : local.fold(0, (s, p) => s + p.sizeBytes);
    final byKey = {for (final r in local) r.packKey: r};
    final missing = remote.where((p) => byKey[p.packKey] == null).toList();
    final active = local.where((r) => r.status == 'downloading' || r.status == 'queued').toList();
    final waiting = local.any((r) => r.status == 'waiting_wifi');
    final stopped = local.where((r) => r.status == 'paused' || r.status == 'failed').toList();
    final stale = remote.where((p) {
      final r = byKey[p.packKey];
      return r != null && r.status == 'ready' && r.version != p.version;
    }).toList();
    final allReady = local.isNotEmpty && missing.isEmpty && local.every((r) => r.status == 'ready');

    Future<void> start(List<OfflinePack> packs, {bool mobileData = false}) =>
        ctl.download(packs, scope: catalog!.scope, scopeTitle: catalog.titleAr, mobileData: mobileData);

    Widget subtitle;
    Widget? trailing;
    if (active.isNotEmpty) {
      final done = local.fold(0, (s, r) => s + r.downloadedBytes);
      final total = local.fold(0, (s, r) => s + r.sizeBytes);
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total == 0 ? null : (done / total).clamp(0, 1)),
          const SizedBox(height: 4),
          Text('جارٍ التحميل · ${formatBytes(done)} من ${formatBytes(total)}'),
        ],
      );
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'إيقاف مؤقت',
            icon: const Icon(Icons.pause),
            onPressed: () {
              for (final r in active) {
                ctl.pause(r.packKey);
              }
            },
          ),
          IconButton(
            tooltip: 'إلغاء التحميل',
            icon: const Icon(Icons.close),
            onPressed: () async {
              for (final r in local) {
                await ctl.cancel(r.packKey);
              }
            },
          ),
        ],
      );
    } else if (waiting) {
      subtitle = const Text('بانتظار الاتصال بشبكة Wi-Fi');
      trailing = TextButton(
        style: _compact,
        onPressed: () async {
          for (final r in local.where((r) => r.status == 'waiting_wifi')) {
            await ctl.resume(r.packKey, mobileData: true);
          }
        },
        child: const Text('تحميل عبر البيانات'),
      );
    } else if (stopped.isNotEmpty) {
      subtitle = Text(stopped.any((r) => r.status == 'failed') ? 'تعذّر إكمال التحميل' : 'متوقف مؤقتاً');
      trailing = TextButton(
        style: _compact,
        onPressed: () async {
          for (final r in stopped) {
            await ctl.resume(r.packKey);
          }
        },
        child: const Text('متابعة'),
      );
    } else if (stale.isNotEmpty) {
      subtitle = Text('تحديث متاح · ${formatBytes(stale.fold(0, (s, p) => s + p.sizeBytes))}');
      trailing = TextButton(
        style: _compact,
        onPressed: catalog == null ? null : () => start(stale),
        child: const Text('تحديث'),
      );
    } else if (allReady) {
      subtitle = Text('محمّل للاستخدام دون اتصال · ${formatBytes(size)}');
      trailing = IconButton(
        tooltip: 'حذف التحميل',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          for (final r in local) {
            await ctl.remove(r.packKey);
          }
        },
      );
    } else {
      subtitle = Text('الحجم التقريبي: ${formatBytes(size)}');
      trailing = FilledButton.tonal(
        style: _compact,
        onPressed: catalog == null ? null : () => start(missing.isEmpty ? remote : missing),
        child: const Text('تحميل'),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(allReady && stale.isEmpty ? Icons.offline_pin : Icons.download_for_offline_outlined),
        title: Text(label),
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

/// After a coupon activates a subject or track (spec §22.2): offer to download it now.
Future<void> offerDownloadAfterRedemption(BuildContext context, WidgetRef ref, ScopeQuery scope) async {
  if (!ref.read(offlinePacksAvailableProvider)) return;
  OfflineScopeCatalog catalog;
  try {
    catalog = await ref.read(offlineScopeCatalogProvider(scope).future);
  } catch (_) {
    return;
  }
  final packs = catalog.packs.where((p) => p.kind != OfflinePackKind.deck).toList();
  if (packs.isEmpty || !context.mounted) return;
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تم تفعيل المادة ✓ هل تريد تحميلها لاستخدامها دون اتصال؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('الحجم التقريبي: ${formatBytes(catalog.sizeBytes)}'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, 'now'), child: const Text('تحميل الآن')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context, 'wifi'), child: const Text('عبر Wi-Fi فقط')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('لاحقاً')),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return;
  await ref
      .read(offlineControllerProvider.notifier)
      .download(packs, scope: catalog.scope, scopeTitle: catalog.titleAr, mobileData: choice == 'now');
}
