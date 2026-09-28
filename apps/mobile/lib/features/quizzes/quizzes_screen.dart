import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/learning/learning_repository.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_banner.dart';
import '../questions/question_providers.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

/// "12 من 30 سؤال متاح" (spec §8.8).
String availabilityLabel(StudentQuiz q) =>
    q.lockedCount == 0 ? questionCountLabel(q.totalCount) : '${q.accessibleCount} من ${q.totalCount} سؤال متاح';

String quizModesLabel(StudentQuiz q) => switch (q.allowedModes) {
  StudentQuizAllowedModes.practice => 'تدريب',
  StudentQuizAllowedModes.exam => 'امتحان',
  _ => 'تدريب أو امتحان',
};

/// Curated quizzes of a subject's general content or of a track (spec §15.1).
class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key, required this.query, required this.title});

  final QuizQuery query;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizzesProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: quizzes,
        onRetry: () => ref.invalidate(quizzesProvider(query)),
        data: (list) => list.isEmpty
            ? const EmptyState('لا توجد اختبارات هنا بعد', icon: Icons.assignment_outlined)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final q in list)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(q.isMockExam ? Icons.timer_outlined : Icons.assignment_outlined),
                            title: Text(q.titleAr),
                            subtitle: Text(
                              [
                                availabilityLabel(q),
                                quizModesLabel(q),
                                if (q.isMockExam) 'امتحان تجريبي',
                                if (q.bestScorePercent != null) 'أفضل نتيجة ${q.bestScorePercent}%',
                              ].join(' · '),
                            ),
                            trailing: Icon(
                              q.locked ? Icons.lock_outline : Icons.chevron_left,
                              semanticLabel: q.locked ? 'مقفل' : null,
                            ),
                            onTap: () => context.go('${Routes.quizzes}/${q.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// A quiz: availability, mode choice (when both are allowed), resume, and past results.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _starting = false;

  Future<void> _start(StudentQuiz q, StartAttemptRequestMode mode) async {
    setState(() => _starting = true);
    try {
      final a = await startAttempt(
        ref.read(learningRepositoryProvider),
        source: StartAttemptRequestSource.curated,
        mode: mode,
        quizId: q.id,
      );
      if (!mounted) return;
      await context.push('/attempts/${a.attempt.id}');
      ref.invalidate(quizProvider(widget.quizId));
      ref.invalidate(quizHistoryProvider(widget.quizId));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider(widget.quizId));
    return Scaffold(
      appBar: AppBar(title: Text(quiz.value?.titleAr ?? 'الاختبار')),
      body: AsyncView(
        value: quiz,
        onRetry: () => ref.invalidate(quizProvider(widget.quizId)),
        data: (q) {
          final text = Theme.of(context).textTheme;
          final exhausted = q.maxAttempts != null && q.attemptsUsed >= q.maxAttempts!;
          final modes = switch (q.allowedModes) {
            StudentQuizAllowedModes.practice => [StartAttemptRequestMode.practice],
            StudentQuizAllowedModes.exam => [StartAttemptRequestMode.exam],
            _ => [StartAttemptRequestMode.practice, StartAttemptRequestMode.exam],
          };
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (q.description != null) ...[Text(q.description!), const SizedBox(height: 12)],
                  Text(availabilityLabel(q), style: text.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (q.timeLimitSeconds != null) 'مدة الامتحان ${humanDuration(q.timeLimitSeconds! * 1000)}',
                      if (q.passingScorePercent != null) 'علامة النجاح ${q.passingScorePercent}%',
                      if (q.maxAttempts != null) 'المحاولات ${q.attemptsUsed} من ${q.maxAttempts}',
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (q.locked || q.lockedCount > 0) const LockedNotice(),
                  if (q.inProgressAttemptId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FilledButton.icon(
                        onPressed: () async {
                          await context.push('/attempts/${q.inProgressAttemptId}');
                          ref.invalidate(quizProvider(widget.quizId));
                          ref.invalidate(quizHistoryProvider(widget.quizId));
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('متابعة الاختبار'),
                      ),
                    ),
                  if (!q.locked && !exhausted)
                    for (final mode in modes)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          enabled: !_starting,
                          leading: Icon(
                            mode == StartAttemptRequestMode.practice ? Icons.school_outlined : Icons.timer_outlined,
                          ),
                          title: Text(mode == StartAttemptRequestMode.practice ? 'وضع التدريب' : 'وضع الامتحان'),
                          subtitle: Text(
                            mode == StartAttemptRequestMode.practice
                                ? 'تحقق من كل إجابة واقرأ الشرح فوراً'
                                : 'لا تصحيح حتى النهاية، مع شبكة الأسئلة والتعليم للمراجعة',
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => _start(q, mode),
                        ),
                      ),
                  if (exhausted) Text('استنفدت عدد المحاولات المسموح', style: TextStyle(color: Colors.orange.shade800)),
                  const SizedBox(height: 16),
                  _History(quizId: q.id),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(quizHistoryProvider(quizId)).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('محاولاتي', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final a in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${a.scorePercent ?? 0}% · ${a.mode == AttemptSummaryMode.exam ? 'امتحان' : 'تدريب'}'),
              subtitle: Text(
                [
                  '${a.correctCount ?? 0} صحيحة من ${a.totalCount}',
                  if (a.submittedLate) 'بعد انتهاء الوقت',
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/attempts/${a.id}/results'),
            ),
          ),
      ],
    );
  }
}

/// `/subjects/:id/quizzes[?lessonId=]`.
class SubjectQuizzesRoute extends ConsumerWidget {
  const SubjectQuizzesRoute({super.key, required this.subjectId, this.lessonId});

  final String subjectId;
  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    return QuizzesScreen(
      query: (subjectId: subjectId, teacherTrackId: null, unitId: null, lessonId: lessonId),
      title: outline != null ? 'اختبارات ${outline.subject.nameAr}' : 'الاختبارات',
    );
  }
}

/// `/tracks/:id/quizzes`.
class TrackQuizzesRoute extends ConsumerWidget {
  const TrackQuizzesRoute({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    return detail.when(
      data: (d) => QuizzesScreen(
        query: (subjectId: d.subject.id, teacherTrackId: trackId, unitId: null, lessonId: null),
        title: 'اختبارات ${d.track.titleAr}',
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(trackProvider(trackId)),
          data: (_) => const SizedBox(),
        ),
      ),
    );
  }
}
