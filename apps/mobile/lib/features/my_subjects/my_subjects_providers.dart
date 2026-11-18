import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../home/home_providers.dart';
import '../learning/scope_learning.dart';
import '../subjects/catalog_providers.dart';

/// The lessons of a subject's general content in path order: units by their order with their lessons
/// by order, then the lessons outside units.
List<Lesson> orderedLessons(SubjectOutline o) {
  int byOrder(num a, num b) => a.compareTo(b);
  final units = [...o.units]..sort((a, b) => byOrder(a.sortOrder, b.sortOrder));
  return [
    for (final u in units) ...([...u.lessons]..sort((a, b) => byOrder(a.sortOrder, b.sortOrder))),
    ...([...o.lessons]..sort((a, b) => byOrder(a.sortOrder, b.sortOrder))),
  ];
}

/// The first lesson below 100 % in path order (lessons without progress count as 0 %), or null when
/// every lesson is done or the subject has none.
Lesson? nextLesson(SubjectOutline outline, ScopeProgress? progress) {
  final done = {
    for (final l in progress?.lessons ?? const <LessonProgress>[])
      if (l.completionPercent >= 100) l.lessonId,
  };
  return orderedLessons(outline).where((l) => !done.contains(l.id)).firstOrNull;
}

/// One tile of «راجع الدرس التالي:» on Home.
typedef NextLessonItem = ({String subjectId, String subjectName, Lesson lesson, int percent});

/// The subjects whose next lesson Home suggests (v3 §2): the subjects in «موادي» (general content or a
/// track of the subject, each once, in the order of [Home.myAccess]); free subjects when the student has
/// no access yet.
List<({String id, String name})> carouselSubjects(Home home) {
  final seen = <String>{};
  final mine = [
    for (final e in home.myAccess)
      if (seen.add(e.scope.subjectId)) (id: e.scope.subjectId, name: e.scope.subjectNameAr),
  ];
  if (mine.isNotEmpty) return mine;
  return [
    for (final f in home.freeSubjects)
      if (seen.add(f.subjectId)) (id: f.subjectId, name: f.nameAr),
  ];
}

/// At most this many subjects are looked up for the carousel (one outline + one progress call each).
const carouselMaxSubjects = 8;

/// «راجع الدرس التالي:»: for each [carouselSubjects] entry, its next lesson below 100 % from the
/// subject outline and the progress endpoint. Subjects that fail to load or are complete are skipped.
final nextLessonsProvider = FutureProvider.autoDispose<List<NextLessonItem>>((ref) async {
  final home = await ref.watch(homeProvider.future);
  final subjects = carouselSubjects(home).take(carouselMaxSubjects).toList();
  // Started together; a failure only drops that subject.
  Future<T?> safe<T>(Future<T> f) => f.then<T?>((v) => v, onError: (Object _) => null);
  final outlines = [for (final s in subjects) safe(ref.watch(subjectOutlineProvider(s.id).future))];
  final progress = [
    for (final s in subjects) safe(ref.watch(progressProvider((subjectId: s.id, teacherTrackId: null)).future)),
  ];
  final items = <NextLessonItem>[];
  for (final (i, s) in subjects.indexed) {
    final outline = await outlines[i];
    if (outline == null) continue;
    final p = await progress[i];
    final lesson = nextLesson(outline, p);
    if (lesson == null) continue;
    final percent = p?.lessons.where((l) => l.lessonId == lesson.id).firstOrNull?.completionPercent ?? 0;
    items.add((subjectId: s.id, subjectName: outline.subject.nameAr, lesson: lesson, percent: percent));
  }
  return items;
});
