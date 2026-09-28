import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/my_decks_repository.dart';
import '../../core/content/my_decks_store.dart';
import '../../core/db/app_database.dart';

final myDecksRepositoryProvider = Provider<MyDecksRepository>((ref) => MyDecksRepository(ref.watch(apiClientProvider)));

final myDecksStoreProvider = Provider<MyDecksStore>((ref) => MyDecksStore(ref.watch(databaseProvider)));

final myDecksProvider = StreamProvider.autoDispose<List<DeckWithCount>>(
  (ref) => ref.watch(myDecksStoreProvider).watchDecks(),
);

final myDeckProvider = StreamProvider.autoDispose.family<LocalDeckRow?, String>(
  (ref, id) => ref.watch(myDecksStoreProvider).watchDeck(id),
);

final myDeckCardsProvider = StreamProvider.autoDispose.family<List<LocalCardRow>, String>(
  (ref, id) => ref.watch(myDecksStoreProvider).watchCards(id),
);

/// Whether the student-decks feature is on (remote flag, §10.2); on when the config is unknown.
final studentDecksEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).value?.features.studentDecks ?? true,
);

/// Rejections from the last sync, shown once as a message.
class SyncNotice extends Notifier<List<SyncRejection>> {
  @override
  List<SyncRejection> build() => const [];

  void set(List<SyncRejection> r) => state = r;
  void clear() => state = const [];
}

final myDecksSyncNoticeProvider = NotifierProvider<SyncNotice, List<SyncRejection>>(SyncNotice.new);

/// Pushes local deck edits and pulls other devices' changes. Offline failures are retried on the
/// next edit or screen open; nothing is lost because rows stay dirty until the server accepts them.
class MyDecksSync {
  MyDecksSync(this.ref);

  final Ref ref;
  Future<void>? _running;
  Timer? _debounce;

  Future<void> syncNow() {
    return _running ??= () async {
      try {
        final repo = ref.read(myDecksRepositoryProvider);
        final store = ref.read(myDecksStoreProvider);
        while (true) {
          final report = await repo.push(store);
          if (report.rejected.isNotEmpty) ref.read(myDecksSyncNoticeProvider.notifier).set(report.rejected);
          if (report.pushed == 0) break;
        }
        await repo.pull(store);
      } catch (_) {
        // Offline or server error: the rows stay dirty for the next attempt.
      } finally {
        _running = null;
      }
    }();
  }

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }
}

final myDecksSyncProvider = Provider<MyDecksSync>((ref) {
  final sync = MyDecksSync(ref);
  ref.onDispose(() => sync._debounce?.cancel());
  return sync;
});

/// Arabic message for a refused item.
String rejectionMessage(SyncRejection r) => switch (r.reason) {
  'deck_quota' => 'وصلت إلى الحد الأقصى: 50 مجموعة',
  'card_quota' => 'وصلت إلى الحد الأقصى: 5000 بطاقة',
  'official_flashcard' => 'لم تعد هذه البطاقة متاحة على حسابك',
  'media' => 'تعذر حفظ الصورة، حاول مرة أخرى',
  _ => 'تعذر حفظ بعض التغييرات',
};
