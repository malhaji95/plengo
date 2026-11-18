import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/question_repository.dart';
import '../../core/offline/offline_repositories.dart';
import '../offline/offline_providers.dart';

/// Questions held in downloaded packs are graded on the device (spec §22.6).
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => OfflineQuestionRepository(ref.watch(apiClientProvider), ref.watch(offlineContentProvider)),
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

/// A question list: the scope, optionally narrowed to categories ([QuestionListKey.categoryIds]: comma
/// separated ids, a parent including its children; [uncategorizedCategory] for the questions filed under
/// no category).
typedef QuestionListKey = ({QuestionQuery query, String? categoryIds});

/// `categoryIds` value that lists the questions without a category («أسئلة أخرى»).
const uncategorizedCategory = 'none';

class QuestionListController extends AsyncNotifier<QuestionListState> {
  QuestionListController(this.key);

  final QuestionListKey key;

  QuestionQuery get query => key.query;
  bool get _uncategorized => key.categoryIds == uncategorizedCategory;
  String? get _categoryIds => _uncategorized ? null : key.categoryIds;

  @override
  Future<QuestionListState> build() async {
    final repo = ref.watch(questionRepositoryProvider);
    var page = await repo.page(query, categoryIds: _categoryIds);
    if (!_uncategorized) {
      return QuestionListState(
        items: page.items,
        nextCursor: page.nextCursor,
        totalCount: page.totalCount,
        accessibleCount: page.accessibleCount,
      );
    }
    // The server cannot filter "no category": read the (small) scope whole and keep those questions.
    final items = [...page.items];
    for (var i = 0; i < 20 && page.nextCursor != null; i++) {
      page = await repo.page(query, cursor: page.nextCursor);
      items.addAll(page.items);
    }
    final shown = items.where((q) => q.categoryId == null).toList();
    return QuestionListState(
      items: shown,
      nextCursor: null,
      totalCount: shown.length,
      accessibleCount: shown.where((q) => !q.locked).length,
    );
  }

  /// Appends the next page, if any.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.nextCursor == null || current.loadingMore) return;
    state = AsyncData(current.copyWith(nextCursor: current.nextCursor, loadingMore: true));
    try {
      final page = await ref
          .read(questionRepositoryProvider)
          .page(query, cursor: current.nextCursor, categoryIds: _categoryIds);
      state = AsyncData(current.copyWith(items: [...current.items, ...page.items], nextCursor: page.nextCursor));
    } catch (_) {
      state = AsyncData(current.copyWith(nextCursor: current.nextCursor, loadingMore: false));
      rethrow;
    }
  }
}

final questionListProvider = AsyncNotifierProvider.autoDispose
    .family<QuestionListController, QuestionListState, QuestionListKey>(QuestionListController.new);

/// The question categories of a scope (unit or lesson) with their counts (v3 §3, §5).
final questionCategoriesProvider = FutureProvider.autoDispose.family<StudentQuestionCategoryList, QuestionQuery>(
  (ref, q) => ref.watch(questionRepositoryProvider).categories(q),
);

/// A top-level category with its children; counts include the children (the server counts each
/// category's own questions).
class CategoryGroup {
  const CategoryGroup({required this.category, required this.children});

  final StudentQuestionCategory category;
  final List<StudentQuestionCategory> children;

  String get id => category.id;
  String get nameAr => category.nameAr;
  int get questionCount => category.questionCount + children.fold(0, (n, c) => n + c.questionCount);
  int get accessibleCount => category.accessibleCount + children.fold(0, (n, c) => n + c.accessibleCount);
}

/// Groups [items] (in the server's tree order) under their parents. Categories without questions are
/// left out unless [keepEmpty]; a child whose parent is not listed stands on its own.
List<CategoryGroup> groupCategories(List<StudentQuestionCategory> items, {bool keepEmpty = false}) {
  final ids = {for (final c in items) c.id};
  final children = <String, List<StudentQuestionCategory>>{};
  for (final c in items) {
    if (c.parentId != null && ids.contains(c.parentId) && (keepEmpty || c.questionCount > 0)) {
      (children[c.parentId!] ??= []).add(c);
    }
  }
  return [
    for (final c in items)
      if (c.parentId == null || !ids.contains(c.parentId))
        CategoryGroup(category: c, children: children[c.id] ?? const []),
  ].where((g) => keepEmpty || g.questionCount > 0).toList();
}

/// Adds up the counts of several lists of the same subject (one per lesson).
StudentQuestionCategoryList mergeCategoryLists(List<StudentQuestionCategoryList> lists) {
  if (lists.length == 1) return lists.single;
  final order = <String>[];
  final byId = <String, StudentQuestionCategory>{};
  var uncategorized = const Uncategorized(questionCount: 0, accessibleCount: 0);
  for (final list in lists) {
    for (final c in list.items) {
      final seen = byId[c.id];
      if (seen == null) order.add(c.id);
      byId[c.id] = StudentQuestionCategory(
        id: c.id,
        subjectId: c.subjectId,
        parentId: c.parentId,
        code: c.code,
        nameAr: c.nameAr,
        sortOrder: c.sortOrder,
        questionCount: c.questionCount + (seen?.questionCount ?? 0),
        accessibleCount: c.accessibleCount + (seen?.accessibleCount ?? 0),
      );
    }
    uncategorized = Uncategorized(
      questionCount: uncategorized.questionCount + list.uncategorized.questionCount,
      accessibleCount: uncategorized.accessibleCount + list.uncategorized.accessibleCount,
    );
  }
  return StudentQuestionCategoryList(items: [for (final id in order) byId[id]!], uncategorized: uncategorized);
}

/// Arabic count agreement: سؤال واحد، سؤالان، 3–10 أسئلة، 11+ سؤالاً.
String questionCountLabel(int n) => switch (n) {
  0 => 'لا أسئلة بعد',
  1 => 'سؤال واحد',
  2 => 'سؤالان',
  >= 3 && <= 10 => '$n أسئلة',
  _ => '$n سؤالاً',
};
