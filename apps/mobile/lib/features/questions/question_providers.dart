import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/question_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.watch(apiClientProvider)),
);

/// Loaded pages of a question list.
class QuestionListState {
  const QuestionListState({
    required this.items,
    required this.nextCursor,
    required this.totalCount,
    required this.accessibleCount,
    this.loadingMore = false,
  });

  final List<StudentQuestion> items;
  final String? nextCursor;
  final int totalCount;
  final int accessibleCount;
  final bool loadingMore;

  List<StudentQuestion> get accessible => items.where((q) => !q.locked).toList();

  QuestionListState copyWith({List<StudentQuestion>? items, String? nextCursor, bool? loadingMore}) =>
      QuestionListState(
        items: items ?? this.items,
        nextCursor: nextCursor,
        totalCount: totalCount,
        accessibleCount: accessibleCount,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class QuestionListController extends AsyncNotifier<QuestionListState> {
  QuestionListController(this.query);

  final QuestionQuery query;

  @override
  Future<QuestionListState> build() async {
    final page = await ref.watch(questionRepositoryProvider).page(query);
    return QuestionListState(
      items: page.items,
      nextCursor: page.nextCursor,
      totalCount: page.totalCount,
      accessibleCount: page.accessibleCount,
    );
  }

  /// Appends the next page, if any.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.nextCursor == null || current.loadingMore) return;
    state = AsyncData(current.copyWith(nextCursor: current.nextCursor, loadingMore: true));
    try {
      final page = await ref.read(questionRepositoryProvider).page(query, cursor: current.nextCursor);
      state = AsyncData(current.copyWith(items: [...current.items, ...page.items], nextCursor: page.nextCursor));
    } catch (_) {
      state = AsyncData(current.copyWith(nextCursor: current.nextCursor, loadingMore: false));
      rethrow;
    }
  }
}

final questionListProvider = AsyncNotifierProvider.autoDispose
    .family<QuestionListController, QuestionListState, QuestionQuery>(QuestionListController.new);

/// Arabic count agreement: سؤال واحد، سؤالان، 3–10 أسئلة، 11+ سؤالاً.
String questionCountLabel(int n) => switch (n) {
  0 => 'لا أسئلة بعد',
  1 => 'سؤال واحد',
  2 => 'سؤالان',
  >= 3 && <= 10 => '$n أسئلة',
  _ => '$n سؤالاً',
};
