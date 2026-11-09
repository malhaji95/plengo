import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/learning/learning_repository.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_banner.dart';
import '../questions/question_providers.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import '../../shared/ui/ui.dart';
import '../access/access_format.dart';
import '../subjects/scope_widgets.dart';
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
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth, title: Text(title)),
      body: AsyncView(
        value: quizzes,
        onRetry: () => ref.invalidate(quizzesProvider(query)),
        data: (list) => list.isEmpty
            ? const PlengoEmptyState(title: 'لا توجد اختبارات هنا بعد', icon: Icons.assignment_outlined)
            : ContentWidthBox(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
                  children: [
                    for (final q in list)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                        child: QuizTile(quiz: q),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// A quiz (V-Quiz): chips, duration / pass mark / attempts tiles, resume, the mode choice, past
/// attempts, and a bottom button whose label follows the chosen mode.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.quizId});

  final String quizId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _starting = false;
  StartAttemptRequestMode? _mode;

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
    final q = quiz.value;
    final s = context.surface;
    final exhausted = q != null && q.maxAttempts != null && q.attemptsUsed >= q.maxAttempts!;
    final modes = switch (q?.allowedModes) {
      StudentQuizAllowedModes.practice => [StartAttemptRequestMode.practice],
      StudentQuizAllowedModes.exam => [StartAttemptRequestMode.exam],
      _ => [StartAttemptRequestMode.practice, StartAttemptRequestMode.exam],
    };
    final canStart = q != null && !q.locked && !exhausted;
    final mode = modes.contains(_mode) ? _mode! : modes.first;
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: q == null ? const Text('الاختبار') : null,
      ),
      bottomNavigationBar: canStart
          ? _BottomBar(
              child: PlengoButton(
                key: const Key('quiz.start'),
                label: mode == StartAttemptRequestMode.practice ? 'ابدأ التدريب' : 'ابدأ الامتحان',
                icon: Icons.play_arrow_rounded,
                busy: _starting,
                onPressed: () => _start(q, mode),
              ),
            )
          : null,
      body: AsyncView(
        value: quiz,
        onRetry: () => ref.invalidate(quizProvider(widget.quizId)),
        data: (q) {
          final tiles = [
            if (q.timeLimitSeconds != null)
              (PlengoColors.blue, 'المدة', humanDuration(q.timeLimitSeconds! * 1000), 'مدة الامتحان'),
            if (q.passingScorePercent != null)
              (PlengoColors.green, 'علامة النجاح', percent(q.passingScorePercent!), 'علامة النجاح'),
            if (q.maxAttempts != null)
              (PlengoColors.orange, 'المحاولات', '${q.attemptsUsed} من ${q.maxAttempts}', 'المحاولات'),
          ];
          return ContentWidthBox(
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 28),
              children: [
                if (q.isMockExam || q.bestScorePercent != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (q.isMockExam) const PlengoChip(label: 'امتحان تجريبي', hue: PlengoColors.pink),
                      if (q.bestScorePercent != null)
                        PlengoChip(
                          label: 'أفضل نتيجة ${percent(q.bestScorePercent!)}',
                          hue: PlengoColors.green,
                          icon: Icons.emoji_events_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Semantics(
                  header: true,
                  child: Text(q.titleAr, style: PlengoType.title.copyWith(color: s.ink)),
                ),
                if (q.description != null) Text(q.description!, style: PlengoType.sub.copyWith(color: s.mute)),
                Text(availabilityLabel(q), style: PlengoType.chip.copyWith(color: s.mute, fontSize: 13)),
                const SizedBox(height: PlengoSpace.section),
                if (tiles.isNotEmpty) ...[
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, (hue, caption, value, spoken)) in tiles.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _InfoTile(hue: hue, caption: caption, value: value, spoken: spoken),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: PlengoSpace.section),
                ],
                if (q.locked || q.lockedCount > 0) const LockedNotice(),
                if (q.inProgressAttemptId != null) ...[
                  ListRow(
                    key: const Key('quiz.resume'),
                    background: PlengoColors.yellow.soft,
                    leading: const SubjectIconTile(icon: Icons.play_arrow_rounded, hue: PlengoColors.yellow, size: 40),
                    title: 'لديك اختبار لم يكتمل',
                    trailing: Text(
                      'متابعة الاختبار',
                      style: PlengoType.chip.copyWith(color: PlengoColors.blue.ink, fontSize: 14),
                    ),
                    onTap: () async {
                      await context.push('/attempts/${q.inProgressAttemptId}');
                      ref.invalidate(quizProvider(widget.quizId));
                      ref.invalidate(quizHistoryProvider(widget.quizId));
                    },
                  ),
                  const SizedBox(height: PlengoSpace.section),
                ],
                if (!q.locked && !exhausted) ...[
                  const SectionHeader('اختر الوضع', top: 0),
                  for (final m in modes)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                      child: RadioRow(
                        key: Key('quiz.mode.${m.name}'),
                        title: m == StartAttemptRequestMode.practice ? 'وضع التدريب' : 'وضع الامتحان',
                        caption: m == StartAttemptRequestMode.practice
                            ? 'تحقق من كل إجابة واقرأ الشرح فوراً'
                            : 'لا تصحيح حتى النهاية، مع شبكة الأسئلة والتعليم للمراجعة',
                        selected: m == mode,
                        onTap: _starting ? null : () => setState(() => _mode = m),
                      ),
                    ),
                ],
                if (exhausted)
                  ListRow(
                    background: PlengoColors.orange.soft,
                    leading: const SubjectIconTile(icon: Icons.block_rounded, hue: PlengoColors.orange, size: 40),
                    title: 'استنفدت عدد المحاولات المسموح',
                  ),
                _History(quizId: q.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The bottom slot of the quiz page: card background, 28 top radius, safe area.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
        border: s.isDark ? Border(top: BorderSide(color: s.line)) : null,
        boxShadow: s.isDark ? null : const [BoxShadow(color: Color(0x0F3C2D0A), offset: Offset(0, -6), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
            child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 14), child: child),
          ),
        ),
      ),
    );
  }
}

/// A coloured info tile: a small caption in the hue's ink above the bold value.
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.hue, required this.caption, required this.value, required this.spoken});

  final PlengoHue hue;
  final String caption;
  final String value;
  final String spoken;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$spoken $value',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: PlengoType.caption.copyWith(color: hue.ink)),
          const SizedBox(height: 4),
          Text(value, style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink)),
        ],
      ),
    ),
  );
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
        const SectionHeader('محاولاتي', top: 12),
        for (final a in items)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
            child: ListRow(
              leading: PlengoChip(
                label: percent(a.scorePercent ?? 0),
                hue: switch (a.passed) {
                  true => PlengoColors.green,
                  false => PlengoColors.red,
                  null => PlengoColors.blue,
                },
              ),
              title: [
                if (a.passed == true) 'ناجح',
                if (a.passed == false) 'لم تبلغ علامة النجاح',
                '${a.correctCount ?? 0} صحيحة من ${a.totalCount}',
              ].join(' · '),
              caption: [
                if (a.submittedAt != null) damascusDate(a.submittedAt!),
                a.mode == AttemptSummaryMode.exam ? 'وضع الامتحان' : 'وضع التدريب',
                if (a.submittedLate) 'بعد انتهاء الوقت',
              ].join(' · '),
              onTap: () => context.push('/attempts/${a.id}/results'),
            ),
          ),
      ],
    );
  }
}

/// One curated quiz in a list: an orange row with availability, modes, mock badge and best score;
/// a locked quiz shows the «مقفل» chip instead of the chevron (§8.7).
class QuizTile extends StatelessWidget {
  const QuizTile({super.key, required this.quiz});

  final StudentQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final q = quiz;
    return ListRow(
      icon: q.isMockExam ? Icons.timer_rounded : Icons.assignment_rounded,
      hue: PlengoColors.orange,
      title: q.titleAr,
      caption: [
        availabilityLabel(q),
        quizModesLabel(q),
        if (q.isMockExam) 'امتحان تجريبي',
        if (q.bestScorePercent != null) 'أفضل نتيجة ${percent(q.bestScorePercent!)}',
      ].join(' · '),
      trailing: q.locked ? const LockedChip() : null,
      onTap: () => context.go('${Routes.quizzes}/${q.id}'),
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
