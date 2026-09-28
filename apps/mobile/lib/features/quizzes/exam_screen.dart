import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

/// Exam mode (spec §15.2): no feedback until the end, a question grid, flags (علّم للمراجعة),
/// a review screen before إنهاء الامتحان, and an optional server-authoritative timer. Answers are
/// saved on the device first, so the exam continues through connection drops.
class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  Timer? _ticker;
  bool _submitting = false;
  bool _autoSubmitted = false;

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

  Future<void> _review(ExamState s) async {
    final unanswered = [
      for (final (i, q) in s.questions.indexed)
        if (!s.answerOf(q.questionId).answered) i,
    ];
    final flagged = [
      for (final (i, q) in s.questions.indexed)
        if (s.answerOf(q.questionId).flagged) i,
    ];
    final go = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مراجعة قبل الإنهاء', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('أجبت عن ${s.answeredCount} من ${s.questions.length}'),
              if (unanswered.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('بلا إجابة (${unanswered.length}):'),
                _IndexChips(indexes: unanswered, onTap: (i) => Navigator.pop(context, i)),
              ],
              if (flagged.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('المعلّمة للمراجعة (${flagged.length}):'),
                _IndexChips(indexes: flagged, onTap: (i) => Navigator.pop(context, i)),
              ],
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنهاء الامتحان')),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('متابعة الإجابة')),
            ],
          ),
        ),
      ),
    );
    if (go is int) _controller.goTo(go);
    if (go == true) await _submit();
  }

  void _grid(ExamState s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _QuestionGrid(
            state: s,
            onTap: (i) {
              Navigator.pop(context);
              _controller.goTo(i);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider(widget.attemptId));
    final s = exam.value;
    final left = s == null ? null : _controller.remainingMs(s);
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.attempt.attempt.titleAr ?? 'الامتحان'),
        actions: [
          if (left != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(isolateLtr(formatDuration(left)), key: const Key('exam-timer')),
                  backgroundColor: left < 60000 ? Theme.of(context).colorScheme.errorContainer : null,
                ),
              ),
            ),
          if (s != null)
            IconButton(tooltip: 'شبكة الأسئلة', icon: const Icon(Icons.grid_view), onPressed: () => _grid(s)),
        ],
      ),
      body: AsyncView(
        value: exam,
        onRetry: () => ref.invalidate(examControllerProvider(widget.attemptId)),
        data: (s) => s.submitPending ? _pending(s) : _question(s),
      ),
    );
  }

  Widget _pending(ExamState s) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'تم حفظ إجاباتك على الجهاز. سيُرسل الامتحان تلقائياً عند عودة الاتصال.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('إرسال الآن'),
          ),
        ],
      ),
    ),
  );

  Widget _question(ExamState s) {
    final q = s.current;
    final a = s.answerOf(q.questionId);
    return Column(
      children: [
        if (s.offline)
          OfflineBanner(text: 'لا يوجد اتصال. تُحفظ إجاباتك على الجهاز وتُرسل لاحقاً.', onRetry: _controller.retry),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  LinearProgressIndicator(value: s.answeredCount / s.questions.length),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'السؤال ${s.index + 1} من ${s.questions.length} · أجبت عن ${s.answeredCount}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      FilterChip(
                        key: const Key('flag'),
                        avatar: Icon(a.flagged ? Icons.flag : Icons.outlined_flag, size: 18),
                        label: const Text('علّم للمراجعة'),
                        selected: a.flagged,
                        showCheckmark: false,
                        onSelected: (_) => _controller.toggleFlag(q.questionId),
                      ),
                    ],
                  ),
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
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: s.index > 0 ? () => _controller.goTo(s.index - 1) : null,
                    child: const Text('السابق'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: s.index < s.questions.length - 1
                      ? FilledButton(onPressed: () => _controller.goTo(s.index + 1), child: const Text('التالي'))
                      : FilledButton(
                          onPressed: _submitting ? null : () => _review(s),
                          child: const Text('إنهاء الامتحان'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IndexChips extends StatelessWidget {
  const _IndexChips({required this.indexes, required this.onTap});

  final List<int> indexes;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [for (final i in indexes) ActionChip(label: Text('${i + 1}'), onPressed: () => onTap(i))],
  );
}

/// Numbered cells: filled = answered, flag = flagged, outline = current.
class _QuestionGrid extends StatelessWidget {
  const _QuestionGrid({required this.state, required this.onTap});

  final ExamState state;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (i, q) in state.questions.indexed)
          Builder(
            builder: (context) {
              final a = state.answerOf(q.questionId);
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onTap(i),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: a.answered ? scheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: i == state.index ? scheme.primary : scheme.outlineVariant,
                      width: i == state.index ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('${i + 1}', semanticsLabel: 'السؤال ${i + 1}${a.answered ? ' مُجاب' : ''}'),
                      if (a.flagged)
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: Icon(Icons.flag, size: 12, color: scheme.error, semanticLabel: 'معلّم'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
