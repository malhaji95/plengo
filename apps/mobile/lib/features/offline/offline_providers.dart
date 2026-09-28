import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/db/app_database.dart';
import '../../core/offline/local_learning.dart';
import '../../core/offline/offline_content.dart';
import '../../core/offline/pack_downloader.dart';
import '../../core/offline/pack_store.dart';
import '../flashcards/flashcard_providers.dart';
import '../reports/report_sheet.dart';

/// Offline packs exist on Android and iOS only (spec §22.8).
final offlinePacksAvailableProvider = Provider<bool>((ref) => !ref.watch(appEnvironmentProvider).isWeb);

final packStoreProvider = Provider<PackStore>((ref) => PackStore(ref.watch(databaseProvider)));

/// Whether the device is on an unmetered connection; tests replace it.
final onWifiProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final types = await Connectivity().checkConnectivity();
    return types.contains(ConnectivityResult.wifi) || types.contains(ConnectivityResult.ethernet);
  },
);

/// Connection changes (a returning connection triggers the offline sync); tests replace it.
final connectivityChangesProvider = Provider<Stream<Object?>>((ref) => Connectivity().onConnectivityChanged);

final leaseManagerProvider = Provider<LeaseManager>(
  (ref) => LeaseManager(
    client: ref.watch(apiClientProvider),
    store: ref.watch(packStoreProvider),
    files: ref.watch(packFilesProvider),
    clock: ref.watch(clockProvider),
  ),
);

final offlineContentProvider = Provider<OfflineContent>(
  (ref) => OfflineContent(
    store: ref.watch(packStoreProvider),
    leases: ref.watch(leaseManagerProvider),
    files: ref.watch(packFilesProvider),
  ),
);

final localAttemptStoreProvider = Provider<LocalAttemptStore>((ref) => LocalAttemptStore(ref.watch(databaseProvider)));

final offlineAttemptSyncProvider = Provider<OfflineAttemptSync>(
  (ref) => OfflineAttemptSync(client: ref.watch(apiClientProvider), local: ref.watch(localAttemptStoreProvider)),
);

final packsProvider = StreamProvider<List<OfflinePackRow>>((ref) => ref.watch(packStoreProvider).watchPacks());

typedef ScopeQuery = ({String subjectId, String? teacherTrackId});

final offlineScopeCatalogProvider = FutureProvider.autoDispose.family<OfflineScopeCatalog, ScopeQuery>(
  (ref, q) => guardApi(
    () async =>
        (await ref
                .watch(apiClientProvider)
                .api
                .offline
                .offlineScopeCatalog(subjectId: q.subjectId, teacherTrackId: q.teacherTrackId))
            .data,
  ),
);

/// Runs downloads one at a time in the background of the app (they continue across screens),
/// refreshes leases and uploads offline attempts.
class OfflineController extends Notifier<String?> {
  final _queue = <({String key, bool mobileData})>[];
  bool _running = false;
  late final PackDownloader _downloader = PackDownloader(
    client: ref.read(apiClientProvider),
    store: ref.read(packStoreProvider),
    files: ref.read(packFilesProvider),
    onWifi: ref.read(onWifiProvider),
    clock: ref.read(clockProvider),
  );

  /// The pack downloading now, if any.
  @override
  String? build() => null;

  PackStore get _store => ref.read(packStoreProvider);

  /// Adds packs to the queue; [mobileData] allows this download over mobile data.
  Future<void> download(
    List<OfflinePack> packs, {
    required OfflineScope scope,
    required String scopeTitle,
    bool mobileData = false,
  }) async {
    for (final p in packs) {
      await _downloader.enqueue(p, scope: scope, scopeTitle: scopeTitle);
      _queue.removeWhere((q) => q.key == p.packKey);
      _queue.add((key: p.packKey, mobileData: mobileData));
    }
    unawaited(_run());
  }

  Future<void> resume(String key, {bool mobileData = false}) async {
    _queue.add((key: key, mobileData: mobileData));
    unawaited(_run());
  }

  void pause(String key) {
    _queue.removeWhere((q) => q.key == key);
    if (state == key) {
      _downloader.pause(key);
    } else {
      unawaited(_store.updatePack(key, const OfflinePacksCompanion(status: Value('paused'))));
    }
  }

  Future<void> cancel(String key) async {
    _queue.removeWhere((q) => q.key == key);
    await _downloader.cancel(key);
  }

  Future<void> remove(String key) => _downloader.remove(key);

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        state = next.key;
        try {
          await _downloader.download(next.key, allowMobileData: next.mobileData);
        } on DownloadStopped {
          // Paused, cancelled or waiting for Wi-Fi: the pack row says which.
        } on ApiException {
          // Offline or refused: the pack is marked failed and can be retried.
        }
      }
    } finally {
      state = null;
      _running = false;
    }
    // Premium packs need a lease right away.
    unawaited(refreshLeases());
  }

  /// Lease refresh, upload of offline attempts and pack updates; each step is skipped when offline.
  Future<void> syncOnline() async {
    // Reports written offline (§22.7) go on every platform.
    try {
      await ref.read(reportRepositoryProvider).flush();
    } catch (_) {}
    if (!ref.read(offlinePacksAvailableProvider)) return;
    await refreshLeases();
    try {
      await ref.read(offlineAttemptSyncProvider).push();
    } catch (_) {}
    await checkUpdates();
  }

  Future<void> refreshLeases({bool force = false}) async {
    try {
      await ref.read(leaseManagerProvider).refresh(force: force);
    } catch (_) {}
  }

  /// Marks packs with a newer server version ("تحديث متاح") and updates them when allowed (§22.3).
  Future<void> checkUpdates() async {
    final byScope = <String, List<OfflinePackRow>>{};
    for (final p in await _store.packs()) {
      if (p.status == 'ready') byScope.putIfAbsent(packScopeKey(p), () => []).add(p);
    }
    final auto = await _store.autoUpdate();
    for (final packs in byScope.values) {
      final first = packs.first;
      OfflineScopeCatalog catalog;
      try {
        catalog =
            (await ref
                    .read(apiClientProvider)
                    .api
                    .offline
                    .offlineScopeCatalog(
                      subjectId: first.subjectId ?? '',
                      teacherTrackId: first.scopeType == 'teacher_track' ? first.teacherTrackId : null,
                    ))
                .data;
      } catch (_) {
        continue;
      }
      final remote = {for (final p in catalog.packs) p.packKey: p};
      final stale = <OfflinePack>[];
      for (final p in packs) {
        final r = remote[p.packKey];
        if (r == null) continue;
        if (r.version != p.version) {
          await _store.updatePack(
            p.packKey,
            OfflinePacksCompanion(remoteVersion: Value(r.version), sizeBytes: Value(r.sizeBytes)),
          );
          stale.add(r);
        }
      }
      if (auto && stale.isNotEmpty) {
        await download(stale, scope: catalog.scope, scopeTitle: catalog.titleAr);
      }
    }
  }
}

final offlineControllerProvider = NotifierProvider<OfflineController, String?>(OfflineController.new);

/// Formats a byte count for download buttons ("12.5 ميغابايت").
String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} كيلوبايت';
  final mb = bytes / (1024 * 1024);
  return '${mb < 10 ? mb.toStringAsFixed(1) : mb.round()} ميغابايت';
}
