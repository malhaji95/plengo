import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../quizzes/quiz_providers.dart';

String bookmarkKey(BookmarkItemType type, String id) => '${type.toJson()}:$id';

/// The student's bookmarked items as `type:id` keys, for the toggle buttons (spec §17).
class BookmarkKeys extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async => {
    for (final k in await ref.watch(learningRepositoryProvider).bookmarkKeys()) bookmarkKey(k.itemType, k.itemId),
  };

  /// Optimistic toggle; reverts when the server refuses.
  Future<void> toggle(BookmarkItemType type, String id) async {
    final current = state.value ?? {};
    final key = bookmarkKey(type, id);
    final saved = current.contains(key);
    state = AsyncData(saved ? ({...current}..remove(key)) : {...current, key});
    try {
      final repo = ref.read(learningRepositoryProvider);
      saved ? await repo.removeBookmark(type, id) : await repo.addBookmark(type, id);
      ref.invalidate(bookmarksProvider);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final bookmarkKeysProvider = AsyncNotifierProvider<BookmarkKeys, Set<String>>(BookmarkKeys.new);

final bookmarksProvider = FutureProvider.autoDispose<BookmarkList>(
  (ref) => ref.watch(learningRepositoryProvider).bookmarks(),
);
