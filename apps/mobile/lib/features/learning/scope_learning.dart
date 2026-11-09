import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../quizzes/quiz_providers.dart';
import '../../core/api/generated/export.dart';

/// Scope progress and the Arabic count labels shared by the subject, track, lesson and Home pages.
typedef ProgressQuery = ({String subjectId, String? teacherTrackId});

final progressProvider = FutureProvider.autoDispose.family<ScopeProgress, ProgressQuery>(
  (ref, q) => ref.watch(learningRepositoryProvider).progress(q.subjectId, teacherTrackId: q.teacherTrackId),
);

/// Arabic count agreement for quizzes: اختبار واحد، اختباران، 3–10 اختبارات، 11+ اختباراً.
String quizCountLabel(int n) => switch (n) {
  1 => 'اختبار واحد',
  2 => 'اختباران',
  >= 3 && <= 10 => '$n اختبارات',
  _ => '$n اختباراً',
};

/// Arabic count agreement for decks: مجموعة واحدة، مجموعتان، 3–10 مجموعات، 11+ مجموعة.
String deckCountLabel(ContentCount c) {
  final decks = switch (c.total) {
    1 => 'مجموعة واحدة',
    2 => 'مجموعتان',
    >= 3 && <= 10 => '${c.total} مجموعات',
    _ => '${c.total} مجموعة',
  };
  return c.free > 0 ? '$decks · ${c.free} مجانية' : decks;
}
