import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/db/app_database.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import 'offline_providers.dart';

/// Download control for a deck ("تحميل البطاقات"), a unit ("تحميل الوحدة") or a whole subject or
/// track ("تحميل الكل") (spec §22.1–§22.2): shows the size first, then progress with pause and
/// cancel, "تحديث متاح" when the server has a newer version, and "محمّل" when done. Styled per
/// docs/redesign DESIGN_SPEC §7.
class OfflineDownloadTile extends ConsumerWidget {
  const OfflineDownloadTile({
    super.key,
    required this.scope,
    required this.label,
    required this.doneLabel,
    this.unitId,
    this.deckId,
  });

  final ScopeQuery scope;

  /// The action, e.g. «تحميل الوحدة».
  final String label;

  /// Shown instead of [label] once everything is on the device, e.g. «الوحدة محمّلة».
  final String doneLabel;
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

    final done = allReady && stale.isEmpty;
    Widget subtitle;
    Widget? below;
    final actions = <Widget>[];
    var hue = PlengoColors.blue;
    if (active.isNotEmpty) {
      final got = local.fold(0, (s, r) => s + r.downloadedBytes);
      final total = local.fold(0, (s, r) => s + r.sizeBytes);
      final fraction = total == 0 ? 0.0 : (got / total).clamp(0.0, 1.0);
      below = PlengoProgressBar(
        value: fraction,
        label: '${percent((fraction * 100).round())} · ${formatBytes(got)} من ${formatBytes(total)}',
      );
      subtitle = const Text('جارٍ التحميل');
      actions
        ..add(
          PlengoIconButton(
            tooltip: 'إيقاف مؤقت',
            icon: Icons.pause_rounded,
            onPressed: () {
              for (final r in active) {
                ctl.pause(r.packKey);
              }
            },
          ),
        )
        ..add(
          PlengoIconButton(
            tooltip: 'إلغاء التحميل',
            icon: Icons.close_rounded,
            onPressed: () async {
              for (final r in local) {
                await ctl.cancel(r.packKey);
              }
            },
          ),
        );
    } else if (waiting) {
      hue = PlengoColors.orange;
      subtitle = const Text('بانتظار الاتصال بشبكة Wi-Fi');
      actions.add(
        PlengoButton(
          label: 'تحميل عبر البيانات',
          variant: PlengoButtonVariant.secondary,
          size: PlengoButtonSize.small,
          onPressed: () async {
            for (final r in local.where((r) => r.status == 'waiting_wifi')) {
              await ctl.resume(r.packKey, mobileData: true);
            }
          },
        ),
      );
    } else if (stopped.isNotEmpty) {
      final failed = stopped.any((r) => r.status == 'failed');
      hue = failed ? PlengoColors.red : PlengoColors.orange;
      subtitle = Text(failed ? 'تعذّر إكمال التحميل' : 'متوقف مؤقتاً');
      actions.add(
        PlengoButton(
          label: 'متابعة',
          icon: Icons.play_arrow_rounded,
          size: PlengoButtonSize.small,
          onPressed: () async {
            for (final r in stopped) {
              await ctl.resume(r.packKey);
            }
          },
        ),
      );
    } else if (stale.isNotEmpty) {
      hue = PlengoColors.yellow;
      subtitle = Text('تحديث متاح · ${formatBytes(stale.fold(0, (s, p) => s + p.sizeBytes))}');
      actions.add(
        PlengoButton(
          label: 'تحديث',
          icon: Icons.sync_rounded,
          size: PlengoButtonSize.small,
          onPressed: catalog == null ? null : () => start(stale),
        ),
      );
    } else if (allReady) {
      subtitle = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const PlengoChip(label: 'متاح دون اتصال', icon: Icons.download_done_rounded),
            Text(formatBytes(size)),
          ],
        ),
      );
      actions.add(
        PlengoIconButton(
          tooltip: 'حذف التحميل',
          icon: Icons.delete_outline_rounded,
          soft: false,
          onPressed: () async {
            for (final r in local) {
              await ctl.remove(r.packKey);
            }
          },
        ),
      );
    } else {
      subtitle = Text('الحجم التقريبي: ${formatBytes(size)}');
      actions.add(
        PlengoButton(
          label: 'تحميل',
          icon: Icons.download_rounded,
          size: PlengoButtonSize.small,
          onPressed: catalog == null ? null : () => start(missing.isEmpty ? remote : missing),
        ),
      );
    }
    final surface = context.surface;
    return PlengoCard(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SubjectIconTile(
                icon: done ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined,
                hue: done ? PlengoColors.green : hue,
                size: 40,
                soft: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(done ? doneLabel : label, style: PlengoType.rowTitle.copyWith(color: surface.ink)),
                    DefaultTextStyle.merge(
                      style: PlengoType.caption.copyWith(color: surface.mute),
                      child: subtitle,
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
          if (below != null) ...[const SizedBox(height: 10), below],
        ],
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
  final choice = await showPlengoSheet<String>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تم تفعيل المادة. هل تريد تحميلها لاستخدامها دون اتصال؟',
          style: PlengoType.section.copyWith(color: sheet.surface.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'الحجم التقريبي: ${formatBytes(catalog.sizeBytes)}',
          style: PlengoType.sub.copyWith(color: sheet.surface.mute),
        ),
        const SizedBox(height: 16),
        PlengoButton(label: 'تحميل الآن', icon: Icons.download_rounded, onPressed: () => Navigator.pop(sheet, 'now')),
        const SizedBox(height: 10),
        PlengoButton(
          label: 'عبر Wi-Fi فقط',
          variant: PlengoButtonVariant.secondary,
          onPressed: () => Navigator.pop(sheet, 'wifi'),
        ),
        const SizedBox(height: 4),
        PlengoButton(label: 'لاحقاً', variant: PlengoButtonVariant.ghost, onPressed: () => Navigator.pop(sheet)),
      ],
    ),
  );
  if (choice == null) return;
  await ref
      .read(offlineControllerProvider.notifier)
      .download(packs, scope: catalog.scope, scopeTitle: catalog.titleAr, mobileData: choice == 'now');
}
