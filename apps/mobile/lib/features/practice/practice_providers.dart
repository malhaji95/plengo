import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/question_repository.dart' show QuestionQuery;
import '../questions/question_providers.dart';
import '../subjects/catalog_providers.dart';

/// The subjects of the student's own stage (their placement), for تدرّب (v3 §5). Empty without a stage.
final practiceSubjectsProvider = FutureProvider.autoDispose<List<CatalogSubject>>((ref) async {
  final me = ref.watch(authControllerProvider).value;
  final levelId = me?.educationLevelId;
  if (me == null || levelId == null) return const [];
  return ref.watch(
    subjectsProvider((
      levelId: levelId,
      universityId: me.universityId,
      facultyId: me.facultyId,
      academicYearId: me.academicYearId,
    )).future,
  );
});

/// What the practice setup counts categories for: a subject, optionally one unit, and either every
/// lesson of that scope ([lessonIds] null) or some of them (comma separated).
typedef PracticeScope = ({String subjectId, String? unitId, String? lessonIds});

const _noCategories = StudentQuestionCategoryList(
  items: [],
  uncategorized: Uncategorized(questionCount: 0, accessibleCount: 0),
);

/// Question categories with counts for the setup's selection: one call for a whole unit (or subject),
/// else one per chosen lesson, added up.
final practiceCategoriesProvider = FutureProvider.autoDispose.family<StudentQuestionCategoryList, PracticeScope>((
  ref,
  scope,
) async {
  QuestionQuery query({String? unitId, String? lessonId}) =>
      (subjectId: scope.subjectId, teacherTrackId: null, unitId: unitId, lessonId: lessonId);
  final lessonIds = scope.lessonIds;
  if (lessonIds == null) return ref.watch(questionCategoriesProvider(query(unitId: scope.unitId)).future);
  final ids = lessonIds.split(',').where((id) => id.isNotEmpty).toList();
  if (ids.isEmpty) return _noCategories;
  final lists = await Future.wait([
    for (final id in ids) ref.watch(questionCategoriesProvider(query(lessonId: id)).future),
  ]);
  return mergeCategoryLists(lists);
});

/// The «عدد الأسئلة» choices; [practiceAllQuestions] is «جميع الأسئلة».
const practiceCounts = [10, 20, 30, practiceAllQuestions];
const practiceAllQuestions = 0;

/// The selected category ids that still apply: a selected parent covers its children (the server
/// includes them), and categories no longer listed for the selection are dropped. In list order.
List<String> effectiveCategoryIds(List<CategoryGroup> groups, Set<String> selected) => [
  for (final g in groups)
    if (selected.contains(g.id))
      g.id
    else
      for (final c in g.children)
        if (selected.contains(c.id)) c.id,
];

/// How many questions of [list] match [categoryIds] (none: every question): `accessible` are open to
/// the student now, `total` includes locked ones.
({int accessible, int total}) matchingCount(StudentQuestionCategoryList list, List<String> categoryIds) {
  if (categoryIds.isEmpty) {
    return (
      accessible: list.items.fold(list.uncategorized.accessibleCount, (n, c) => n + c.accessibleCount),
      total: list.items.fold(list.uncategorized.questionCount, (n, c) => n + c.questionCount),
    );
  }
  final wanted = categoryIds.toSet();
  var accessible = 0;
  var total = 0;
  for (final g in groupCategories(list.items, keepEmpty: true)) {
    if (wanted.contains(g.id)) {
      accessible += g.accessibleCount;
      total += g.questionCount;
      continue;
    }
    for (final c in g.children.where((c) => wanted.contains(c.id))) {
      accessible += c.accessibleCount;
      total += c.questionCount;
    }
  }
  return (accessible: accessible, total: total);
}

/// The attempt filters of a practice setup (v3 §5). Every lesson of the scope chosen: the unit (or
/// subject) alone; some: `lessonIds`. [count] [practiceAllQuestions] asks for every match
/// (`allQuestions`, the server caps it).
AttemptFilters practiceFilters({
  required String subjectId,
  required String? unitId,
  required List<String> scopeLessonIds,
  required Set<String> selectedLessonIds,
  required List<String> categoryIds,
  required Set<AttemptFiltersTypes> types,
  required int count,
}) {
  final everyLesson = scopeLessonIds.every(selectedLessonIds.contains);
  return AttemptFilters(
    subjectId: subjectId,
    unitId: unitId,
    lessonIds: everyLesson
        ? null
        : [
            for (final id in scopeLessonIds)
              if (selectedLessonIds.contains(id)) id,
          ],
    categoryIds: categoryIds.isEmpty ? null : categoryIds,
    types: types.isEmpty
        ? null
        : [
            for (final t in AttemptFiltersTypes.values)
              if (types.contains(t)) t,
          ],
    count: count == practiceAllQuestions ? null : count,
    allQuestions: count == practiceAllQuestions ? true : null,
  );
}
