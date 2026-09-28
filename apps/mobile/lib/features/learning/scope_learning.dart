import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../quizzes/quiz_providers.dart';

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

/// Quizzes, random practice and progress for one scope (a subject's general content or a track).
class ScopeLearning extends ConsumerWidget {
  const ScopeLearning({
    super.key,
    required this.subjectId,
    this.teacherTrackId,
    required this.quizCount,
    required this.questionCount,
    required this.quizzesPath,
  });

  final String subjectId;
  final String? teacherTrackId;
  final ContentCount quizCount;
  final ContentCount questionCount;
  final String quizzesPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomEnabled = ref.watch(remoteConfigProvider).value?.features.randomPractice ?? true;
    final progress = ref.watch(progressProvider((subjectId: subjectId, teacherTrackId: teacherTrackId))).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress != null && progress.completionPercent > 0) ProgressCard(progress: progress),
        if (quizCount.total > 0)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('الاختبارات'),
              subtitle: Text(
                quizCount.free > 0
                    ? '${quizCountLabel(quizCount.total)} · ${quizCount.free} مجاني'
                    : quizCountLabel(quizCount.total),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(quizzesPath),
            ),
          ),
        if (randomEnabled && questionCount.total > 0)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('تدريب عشوائي'),
              subtitle: const Text('اختر الوحدة والنوع وعدد الأسئلة'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push(
                Uri(
                  path: Routes.randomPractice,
                  queryParameters: {'subjectId': subjectId, 'teacherTrackId': ?teacherTrackId},
                ).toString(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Completion and counts for a scope (spec §18).
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.progress});

  final ScopeProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('تقدّمي', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(percent(p.completionPercent), key: const Key('completion')),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: p.completionPercent / 100),
            const SizedBox(height: 8),
            Text(
              [
                if (p.questionsTotal > 0) 'الأسئلة ${p.questionsAttempted}/${p.questionsTotal}',
                if (p.quizzesTotal > 0) 'الاختبارات ${p.quizzesCompleted}/${p.quizzesTotal}',
                if (p.flashcardsTotal > 0) 'البطاقات ${p.flashcardsStudied}/${p.flashcardsTotal}',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
