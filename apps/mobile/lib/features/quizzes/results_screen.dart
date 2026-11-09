import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../home/home_providers.dart';
import '../home/streak_moment.dart';
import '../questions/question_view.dart';
import '../reports/report_sheet.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

enum _Filter { all, wrong, skipped, flagged }

const _filterLabels = {
  _Filter.all: 'الكل',
  _Filter.wrong: 'الخاطئة',
  _Filter.skipped: 'المتروكة',
  _Filter.flagged: 'المعلّمة',
};

bool _answered(AttemptQuestion q) => q.selectedOptionId != null || (q.writtenAnswer?.isNotEmpty ?? false);

/// Results (spec §15.6): score, counts, time, pass/fail, the daily goal, retries, then every
/// question with the student's answer, the correct answer and the explanation.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  _Filter _filter = _Filter.all;
  bool _starting = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    // The finished attempt just moved the daily goal: show today's numbers, not the cached ones.
    Future.microtask(() {
      if (mounted) ref.invalidate(homeProvider);
    });
  }

  Future<void> _retry(Attempt a, {required bool wrongOnly}) async {
    final s = a.attempt;
    final repo = ref.read(learningRepositoryProvider);
    final mode = StartAttemptRequestMode.values.byName(s.mode.name);
    setState(() => _starting = true);
    try {
      final Attempt next;
      if (wrongOnly) {
        next = await startAttempt(
          repo,
          source: StartAttemptRequestSource.mistakes,
          mode: StartAttemptRequestMode.practice,
          filters: AttemptFilters(questionIds: _wrongIds(a)),
        );
      } else {
        next = await startAttempt(
          repo,
          source: StartAttemptRequestSource.values.byName(s.source.name),
          mode: mode,
          quizId: s.quizId,
          filters: s.filters,
        );
      }
      if (mounted) context.pushReplacement('/attempts/${next.attempt.id}');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  List<String> _wrongIds(Attempt a) => [
    for (final q in a.questions)
      if (q.result != null && !q.result!.isCorrect && _answered(q)) q.questionId,
  ];

  /// «متابعة»: the streak moment (once a day), then Home.
  Future<void> _continue() async {
    setState(() => _leaving = true);
    await maybeShowStreakMoment(context, ref);
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(attemptProvider(widget.attemptId));
    final ready = attempt.hasValue;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
              child: Row(
                children: [
                  PlengoIconButton(icon: Icons.close_rounded, tooltip: 'إغلاق', onPressed: () => leaveFlow(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('النتيجة', style: PlengoType.section.copyWith(color: context.surface.ink)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncView(
                value: attempt,
                onRetry: () => ref.invalidate(attemptProvider(widget.attemptId)),
                data: _body,
              ),
            ),
            if (ready)
              _BottomButton(
                child: PlengoButton(
                  key: const Key('results-continue'),
                  label: 'متابعة',
                  busy: _leaving,
                  onPressed: _leaving ? null : _continue,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(Attempt a) {
    final shown = a.questions.where(
      (q) => switch (_filter) {
        _Filter.all => true,
        _Filter.wrong => _answered(q) && q.result?.isCorrect == false,
        _Filter.skipped => !_answered(q),
        _Filter.flagged => q.flagged,
      },
    );
    final wrong = (a.attempt.wrongCount ?? 0) > 0;
    final s = context.surface;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 24),
          children: [
            _Hero(summary: a.attempt),
            const SizedBox(height: 16),
            _StatTiles(summary: a.attempt),
            const _DailyGoalRow(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wrong) ...[
                  Expanded(
                    child: PlengoButton(
                      label: 'أعد الأخطاء فقط (${_wrongIds(a).length})',
                      icon: Icons.replay_rounded,
                      variant: PlengoButtonVariant.secondary,
                      onPressed: _starting ? null : () => _retry(a, wrongOnly: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: PlengoButton(
                    label: 'أعد الاختبار',
                    icon: Icons.restart_alt_rounded,
                    variant: PlengoButtonVariant.secondary,
                    onPressed: _starting ? null : () => _retry(a, wrongOnly: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text('مراجعة الإجابات', style: PlengoType.section.copyWith(color: s.ink)),
            ),
            const SizedBox(height: 10),
            PillSelector<_Filter>(
              padding: EdgeInsets.zero,
              options: [for (final f in _Filter.values) PlengoOption(f, _filterLabels[f]!)],
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty) const EmptyState('لا توجد أسئلة هنا', icon: Icons.filter_alt_off_outlined),
            for (final q in shown) ...[
              _ResultCard(index: a.questions.indexOf(q) + 1, question: q),
              const SizedBox(height: PlengoSpace.listGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
        border: s.isDark ? Border(top: BorderSide(color: s.line)) : null,
        boxShadow: s.isDark ? null : const [BoxShadow(color: Color(0x0F3C2D0A), offset: Offset(0, -6), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pass: a trophy in a yellow circle with a soft ring and confetti. Otherwise a target and
/// «واصل التدريب». Then «16 من 20 · ناجح — علامة النجاح 60%» and the score.
class _Hero extends StatelessWidget {
  const _Hero({required this.summary});

  final AttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final passed = summary.passed;
    final score = summary.scorePercent ?? 0;
    final correct = summary.correctCount ?? 0;
    final wrong = summary.wrongCount ?? 0;
    final skipped = summary.skippedCount ?? 0;
    final total = correct + wrong + skipped;
    // Celebrate a pass, or a strong score on quizzes without a passing mark.
    final great = passed ?? score >= 70;
    final hue = great ? PlengoColors.yellow : PlengoColors.blue;
    final mark = summary.passingScorePercent;
    final line = [
      if (total > 0) '$correct من $total',
      if (passed == true) mark == null ? 'ناجح' : 'ناجح — علامة النجاح ${percent(mark)}',
      if (passed == false) 'لم تبلغ علامة النجاح (${percent(mark ?? 0)})',
    ].join(' · ');
    final circle = Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: great ? hue.base : hue.soft,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: great ? hue.soft : s.track, spreadRadius: 12)],
      ),
      child: Icon(
        great ? Icons.emoji_events_rounded : Icons.track_changes_rounded,
        size: 56,
        color: great ? PlengoColors.ink : hue.ink,
      ),
    );
    return Column(
      children: [
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: great
              ? ConfettiDots(spread: 28, child: circle)
              : Padding(padding: const EdgeInsets.all(28), child: circle),
        ),
        Semantics(
          header: true,
          child: Text(
            great ? 'أحسنت!' : 'واصل التدريب',
            textAlign: TextAlign.center,
            style: PlengoType.title.copyWith(color: s.ink),
          ),
        ),
        Text(
          summary.titleAr,
          textAlign: TextAlign.center,
          style: PlengoType.rowTitle.copyWith(color: s.ink),
        ),
        const SizedBox(height: 4),
        if (line.isNotEmpty)
          Text(
            isolateLtr(line),
            textAlign: TextAlign.center,
            style: PlengoType.sub.copyWith(color: passed == false ? PlengoColors.red.ink : s.mute),
          ),
        const SizedBox(height: 6),
        PlengoChip(
          key: const Key('score'),
          label: percent(score),
          hue: great ? PlengoColors.green : PlengoColors.blue,
          semanticsLabel: 'النتيجة ${percent(score)}',
        ),
        if (summary.submittedLate) ...[
          const SizedBox(height: 8),
          Text('تم التسليم بعد انتهاء الوقت', style: PlengoType.sub.copyWith(color: PlengoColors.red.ink)),
        ],
      ],
    );
  }
}

/// صحيحة (green) · خاطئة (red) · متروكة (orange) · الوقت (blue): a coloured label strip on top, an
/// icon and the number below.
class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.summary});

  final AttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Stat(label: 'صحيحة', value: '${summary.correctCount ?? 0}', hue: PlengoColors.green, icon: Icons.check_rounded),
      _Stat(label: 'خاطئة', value: '${summary.wrongCount ?? 0}', hue: PlengoColors.red, icon: Icons.close_rounded),
      _Stat(
        label: 'متروكة',
        value: '${summary.skippedCount ?? 0}',
        hue: PlengoColors.orange,
        icon: Icons.remove_rounded,
      ),
      if (summary.timeSpentMs != null)
        _Stat(
          label: 'الوقت',
          value: humanDuration(summary.timeSpentMs!),
          hue: PlengoColors.blue,
          icon: Icons.timer_outlined,
        ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, t) in tiles.indexed) ...[if (i > 0) const SizedBox(width: 6), Expanded(child: t)],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.hue, required this.icon});

  final String label;
  final String value;
  final PlengoHue hue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    // Blue keeps white text on its strip; the other bright fills take dark ink (spec §2).
    final stripText = hue == PlengoColors.blue ? Colors.white : PlengoColors.ink;
    final valueColor = s.isDark ? s.ink : hue.ink;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hue.base, width: 2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: hue.base,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PlengoType.navLabel.copyWith(fontWeight: FontWeight.w700, color: stripText),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: valueColor),
                        const SizedBox(width: 4),
                        Text(isolateLtr(value), style: PlengoType.rowTitle.copyWith(fontSize: 17, color: valueColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «هدف اليوم: 12 من 20» with a green ring, from Home's today numbers; hidden until they load
/// (and offline).
class _DailyGoalRow extends ConsumerWidget {
  const _DailyGoalRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(homeProvider).value?.today;
    if (today == null || today.goal <= 0) return const SizedBox.shrink();
    final green = PlengoColors.green;
    final value = today.done / today.goal;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        key: const Key('results-goal'),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: green.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
        child: Row(
          children: [
            ProgressRing(
              value: value,
              size: 40,
              strokeWidth: 5,
              label: '${(value.clamp(0, 1) * 100).round()}%',
              trackColor: Colors.white,
              labelStyle: const TextStyle(
                fontFamily: PlengoType.family,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PlengoColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                today.goalMet
                    ? 'أنجزت هدف اليوم: ${today.done} من ${today.goal}'
                    : 'هدف اليوم: ${today.done} من ${today.goal}',
                style: PlengoType.rowTitle.copyWith(fontSize: 14, color: PlengoColors.ink),
              ),
            ),
            if (today.goalMet) Icon(Icons.check_circle_rounded, color: green.ink, semanticLabel: 'تم'),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.index, required this.question});

  final int index;
  final AttemptQuestion question;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final q = question;
    final r = q.result;
    final answered = _answered(q);
    final (String status, PlengoHue hue, IconData? icon) = !answered
        ? ('متروكة', PlengoColors.orange, null)
        : r?.isCorrect == true
        ? ('صحيحة', PlengoColors.green, Icons.check_rounded)
        : ('خاطئة', PlengoColors.red, Icons.close_rounded);
    final String mine;
    final String? right;
    if (q.type == AttemptQuestionType.written) {
      mine = answered ? q.writtenAnswer! : '—';
      right = r?.correctAnswer;
    } else {
      mine = q.options.where((o) => o.id == q.selectedOptionId).firstOrNull?.text ?? '—';
      right = q.options.where((o) => o.isCorrect == true || o.id == r?.correctOptionId).firstOrNull?.text;
    }
    final strong = PlengoType.sub.copyWith(fontWeight: FontWeight.w700, color: s.ink);
    return PlengoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlengoChip(label: status, hue: hue, icon: icon),
                    if (q.flagged)
                      const PlengoChip(label: 'معلّمة', hue: PlengoColors.yellow, icon: Icons.flag_rounded),
                    Text('السؤال $index', style: PlengoType.chip.copyWith(color: s.mute)),
                  ],
                ),
              ),
              ReportButton(type: ReportItemType.question, id: q.questionId, soft: false),
            ],
          ),
          const SizedBox(height: 8),
          Text(isolateLtr(q.questionText), style: PlengoType.rowTitle.copyWith(color: s.ink)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'إجابتك: '),
                TextSpan(text: isolateLtr(mine), style: strong),
              ],
            ),
            style: PlengoType.sub.copyWith(color: s.mute),
          ),
          if (right != null)
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'الإجابة الصحيحة: '),
                  TextSpan(text: isolateLtr(right), style: strong),
                ],
              ),
              style: PlengoType.sub.copyWith(color: s.mute),
            ),
          if (r?.explanation != null) ...[
            Divider(height: 20, color: s.line),
            Text(isolateLtr(r!.explanation!), style: PlengoType.sub.copyWith(color: s.ink)),
          ],
        ],
      ),
    );
  }
}
