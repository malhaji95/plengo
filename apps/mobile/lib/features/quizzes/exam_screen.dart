import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../questions/question_providers.dart';
import '../questions/question_view.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

/// Exam mode (spec §15.2): no feedback until the end, a question grid, flags (علّم للمراجعة),
/// a review sheet before إنهاء الامتحان, and an optional server-authoritative timer. Answers are
/// saved on the device first, so the exam continues through connection drops.
class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key, required this.attemptId});

  final String attemptId;

  /// Exit sheet copy (DECISIONS #12): the timer runs on the server.
  static const exitTitle = 'الخروج من الامتحان؟';
  static const exitMessage = 'إجاباتك محفوظة، لكن الوقت مستمر. يمكنك العودة من صفحة الاختبار بزر «متابعة الاختبار».';

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  Timer? _ticker;
  bool _submitting = false;
  bool _autoSubmitted = false;
  bool _gridOpen = false;

  ExamController get _controller => ref.read(examControllerProvider(widget.attemptId).notifier);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final s = ref.read(examControllerProvider(widget.attemptId)).value;
    if (s == null || !mounted) return;
    final left = _controller.remainingMs(s);
    if (left == null) return; // untimed: nothing to redraw
    if (left <= 0 && !_autoSubmitted && !s.submitPending) {
      _autoSubmitted = true;
      unawaited(_submit());
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _controller.submit();
      if (!mounted) return;
      if (result != null) {
        ref.invalidate(attemptProvider(widget.attemptId));
        context.pushReplacement('/attempts/${widget.attemptId}/results');
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _exit(ExamState? s) async {
    // Nothing left to lose once the exam waits to be sent, or before it loaded.
    if (s == null || s.submitPending) {
      leaveFlow(context);
      return;
    }
    final stay = await showConfirmSheet(
      context,
      title: ExamScreen.exitTitle,
      message: ExamScreen.exitMessage,
      icon: Icons.timer_outlined,
      hue: PlengoColors.yellow,
      primaryLabel: 'واصل الامتحان',
      secondaryLabel: 'خروج',
    );
    if (stay == false && mounted) leaveFlow(context);
  }

  Future<void> _review(ExamState s) async {
    final go = await showPlengoSheet<Object>(
      context: context,
      title: 'مراجعة قبل الإنهاء',
      builder: (context) => ExamReviewSheet(state: s),
    );
    if (go is int) _controller.goTo(go);
    if (go == true) await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider(widget.attemptId));
    final s = exam.value;
    final left = s == null ? null : _controller.remainingMs(s);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 4),
              child: Row(
                children: [
                  PlengoIconButton(icon: Icons.close_rounded, tooltip: 'خروج', onPressed: () => _exit(s)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: s == null || s.submitPending
                        ? const SizedBox.shrink()
                        : Text(
                            'السؤال ${s.index + 1} من ${s.questions.length} · أجبت عن ${s.answeredCount}',
                            style: PlengoType.rowTitle.copyWith(fontSize: 14, color: context.surface.ink),
                          ),
                  ),
                  if (left != null) ...[const SizedBox(width: 8), ExamTimerChip(remainingMs: left)],
                ],
              ),
            ),
            Expanded(
              child: AsyncView(
                value: exam,
                onRetry: () => ref.invalidate(examControllerProvider(widget.attemptId)),
                data: (s) => s.submitPending ? _pending(s) : _question(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pending(ExamState s) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StateIllustration(icon: Icons.cloud_upload_outlined, hue: PlengoColors.blue),
          const SizedBox(height: 16),
          Text(
            'تم حفظ إجاباتك على الجهاز. سيُرسل الامتحان تلقائياً عند عودة الاتصال.',
            textAlign: TextAlign.center,
            style: PlengoType.body.copyWith(color: context.surface.ink),
          ),
          const SizedBox(height: 20),
          PlengoButton(label: 'إرسال الآن', busy: _submitting, onPressed: _submitting ? null : _submit),
        ],
      ),
    ),
  );

  Widget _question(ExamState s) {
    final q = s.current;
    final a = s.answerOf(q.questionId);
    final last = s.index == s.questions.length - 1;
    return Column(
      children: [
        if (s.offline)
          OfflineBanner(text: 'لا يوجد اتصال. تُحفظ إجاباتك على الجهاز وتُرسل لاحقاً.', onRetry: _controller.retry),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 24),
                children: [
                  Text(s.attempt.attempt.titleAr, style: PlengoType.caption.copyWith(color: context.surface.mute)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      expanded: _gridOpen,
                      child: PlengoButton(
                        key: const Key('grid-toggle'),
                        label: 'شبكة الأسئلة',
                        icon: Icons.grid_view_rounded,
                        variant: PlengoButtonVariant.secondary,
                        size: PlengoButtonSize.small,
                        onPressed: () => setState(() => _gridOpen = !_gridOpen),
                      ),
                    ),
                  ),
                  if (_gridOpen) ...[
                    const SizedBox(height: 12),
                    PlengoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExamQuestionGrid(
                            state: s,
                            onTap: (i) {
                              setState(() => _gridOpen = false);
                              _controller.goTo(i);
                            },
                          ),
                          const SizedBox(height: 12),
                          const ExamGridLegend(),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AttemptQuestionBody(
                    key: ValueKey(q.questionId),
                    question: q,
                    selectedOptionId: a.selectedOptionId,
                    writtenAnswer: a.writtenAnswer,
                    enabled: !_submitting,
                    onSelect: (id) => _controller.select(q.questionId, id),
                    onWrite: (text) => _controller.write(q.questionId, text),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      toggled: a.flagged,
                      child: PlengoButton(
                        key: const Key('flag'),
                        label: a.flagged ? 'معلّم للمراجعة' : 'علّم للمراجعة',
                        icon: a.flagged ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                        variant: a.flagged ? PlengoButtonVariant.brand : PlengoButtonVariant.secondary,
                        size: PlengoButtonSize.small,
                        onPressed: () => _controller.toggleFlag(q.questionId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomBar(
          children: [
            Row(
              children: [
                Expanded(
                  child: PlengoButton(
                    label: 'السابق',
                    variant: PlengoButtonVariant.secondary,
                    onPressed: s.index > 0 ? () => _controller.goTo(s.index - 1) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PlengoButton(label: 'التالي', onPressed: last ? null : () => _controller.goTo(s.index + 1)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            PlengoButton(
              label: 'إنهاء الامتحان',
              variant: PlengoButtonVariant.ghost,
              size: PlengoButtonSize.small,
              expand: true,
              onPressed: _submitting ? null : () => _review(s),
            ),
          ],
        ),
      ],
    );
  }
}

/// The card-coloured bottom area with a 28 top radius.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});

  final List<Widget> children;

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
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The countdown chip: blue-soft, then red-soft with a gentle pulse in the last 60 s (no pulse with
/// reduced motion). The digits stay LTR.
class ExamTimerChip extends StatefulWidget {
  const ExamTimerChip({super.key, required this.remainingMs});

  final int remainingMs;

  static const urgentMs = 60000;

  @override
  State<ExamTimerChip> createState() => _ExamTimerChipState();
}

class _ExamTimerChipState extends State<ExamTimerChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  bool get _urgent => widget.remainingMs < ExamTimerChip.urgentMs;

  void _sync() {
    final animate = _urgent && !PlengoMotion.reduced(context);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ExamTimerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hue = _urgent ? PlengoColors.red : PlengoColors.blue;
    final time = formatDuration(widget.remainingMs);
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: hue.soft,
        borderRadius: BorderRadius.circular(PlengoRadius.pill),
        border: _urgent ? Border.all(color: hue.base, width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_urgent ? Icons.timer_off_outlined : Icons.timer_outlined, size: 18, color: hue.ink),
          const SizedBox(width: 6),
          Text(
            isolateLtr(time),
            key: const Key('exam-timer'),
            textDirection: TextDirection.ltr,
            style: PlengoType.chip.copyWith(fontSize: 14, color: hue.ink),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: _urgent ? 'الوقت المتبقي أقل من دقيقة: $time' : 'الوقت المتبقي $time',
      excludeSemantics: true,
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
        child: chip,
      ),
    );
  }
}

/// How a grid cell is drawn; flagged wins over answered (it is what the student asked to revisit).
enum ExamCellState { current, flagged, answered, unanswered }

/// 5 columns of 48 dp squares: answered = blue fill, unanswered = outline, flagged = orange-soft + ⚑,
/// current = yellow with a dark border. Each cell says its state in words to screen readers.
class ExamQuestionGrid extends StatelessWidget {
  const ExamQuestionGrid({super.key, required this.state, required this.onTap});

  final ExamState state;
  final ValueChanged<int> onTap;

  static ExamCellState cellState(ExamState s, int i) {
    final a = s.answerOf(s.questions[i].questionId);
    if (i == s.index) return ExamCellState.current;
    if (a.flagged) return ExamCellState.flagged;
    if (a.answered) return ExamCellState.answered;
    return ExamCellState.unanswered;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: PlengoSpace.examGridCell,
      ),
      itemCount: state.questions.length,
      itemBuilder: (context, i) {
        final a = state.answerOf(state.questions[i].questionId);
        final cell = cellState(state, i);
        final (Color bg, Color border, Color fg) = switch (cell) {
          ExamCellState.current => (PlengoColors.yellow.base, PlengoColors.ink, PlengoColors.ink),
          ExamCellState.flagged => (PlengoColors.orange.soft, PlengoColors.orange.base, PlengoColors.ink),
          ExamCellState.answered => (PlengoColors.blue.base, PlengoColors.blue.base, Colors.white),
          ExamCellState.unanswered => (s.card, const Color(0xFF9A958B), s.ink),
        };
        final label = [
          'السؤال ${i + 1}',
          a.answered ? 'مُجاب' : 'غير مُجاب',
          if (a.flagged) 'معلّم',
          if (i == state.index) 'الحالي',
        ].join('، ');
        final r = BorderRadius.circular(14);
        return Semantics(
          button: true,
          selected: i == state.index,
          label: label,
          excludeSemantics: true,
          onTap: () => onTap(i),
          child: Material(
            key: Key('grid-cell-$i'),
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: r,
              side: BorderSide(color: border, width: 2),
            ),
            child: InkWell(
              borderRadius: r,
              onTap: () => onTap(i),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    a.flagged ? '${i + 1}⚑' : '${i + 1}',
                    style: PlengoType.chip.copyWith(fontSize: 14, color: fg),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What the grid colours mean, in words.
class ExamGridLegend extends StatelessWidget {
  const ExamGridLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    Widget item(Color fill, Color border, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: PlengoType.caption.copyWith(color: s.mute)),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        item(PlengoColors.blue.base, PlengoColors.blue.base, 'مُجاب'),
        item(s.card, const Color(0xFF9A958B), 'غير مُجاب'),
        item(PlengoColors.orange.soft, PlengoColors.orange.base, '⚑ معلّم'),
        item(PlengoColors.yellow.base, PlengoColors.ink, 'الحالي'),
      ],
    );
  }
}

/// Review before finishing: how many are unanswered (orange-soft) and flagged (yellow-soft), with a
/// tap on a number to go back to that question. Pops an index, `true` to finish, or nothing.
class ExamReviewSheet extends StatelessWidget {
  const ExamReviewSheet({super.key, required this.state});

  final ExamState state;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final unanswered = [
      for (final (i, q) in state.questions.indexed)
        if (!state.answerOf(q.questionId).answered) i,
    ];
    final flagged = [
      for (final (i, q) in state.questions.indexed)
        if (state.answerOf(q.questionId).flagged) i,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أجبت عن ${state.answeredCount} من ${state.questions.length}',
          style: PlengoType.sub.copyWith(color: s.mute),
        ),
        const SizedBox(height: 10),
        if (unanswered.isEmpty)
          const _ReviewRow(hue: PlengoColors.green, icon: Icons.check_circle_rounded, title: 'أجبت عن كل الأسئلة')
        else
          _ReviewRow(
            key: const Key('review-unanswered'),
            hue: PlengoColors.orange,
            icon: Icons.help_outline_rounded,
            title: '${questionCountLabel(unanswered.length)} بلا إجابة',
            indexes: unanswered,
          ),
        if (flagged.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ReviewRow(
            key: const Key('review-flagged'),
            hue: PlengoColors.yellow,
            icon: Icons.flag_rounded,
            title: '${flagged.length} معلّم للمراجعة',
            indexes: flagged,
          ),
        ],
        const SizedBox(height: 16),
        PlengoButton(
          label: 'عودة إلى الأسئلة',
          variant: PlengoButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 10),
        PlengoButton(label: 'إنهاء الامتحان الآن', onPressed: () => Navigator.pop(context, true)),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({super.key, required this.hue, required this.icon, required this.title, this.indexes = const []});

  final PlengoHue hue;
  final IconData icon;
  final String title;
  final List<int> indexes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
    decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 22, color: hue.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: PlengoType.rowTitle.copyWith(fontSize: 14, color: PlengoColors.ink)),
            ),
          ],
        ),
        if (indexes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final i in indexes)
                Semantics(
                  button: true,
                  label: 'انتقل إلى السؤال ${i + 1}',
                  excludeSemantics: true,
                  onTap: () => Navigator.pop(context, i),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, i),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        child: Center(
                          widthFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('${i + 1}', style: PlengoType.chip.copyWith(fontSize: 14, color: hue.ink)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}
