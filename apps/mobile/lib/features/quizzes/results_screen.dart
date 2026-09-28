import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../reports/report_sheet.dart';
import '../../shared/widgets/async_view.dart';
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

/// Results (spec §15.6): score, counts, time, pass/fail, then every question with the student's
/// answer, the correct answer and the explanation.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  _Filter _filter = _Filter.all;
  bool _starting = false;

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
          filters: AttemptFilters(
            questionIds: [
              for (final q in a.questions)
                if (q.result != null && !q.result!.isCorrect && _answered(q)) q.questionId,
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(attemptProvider(widget.attemptId));
    return Scaffold(
      appBar: AppBar(title: const Text('النتيجة')),
      body: AsyncView(
        value: attempt,
        onRetry: () => ref.invalidate(attemptProvider(widget.attemptId)),
        data: (a) {
          final shown = a.questions.where(
            (q) => switch (_filter) {
              _Filter.all => true,
              _Filter.wrong => _answered(q) && q.result?.isCorrect == false,
              _Filter.skipped => !_answered(q),
              _Filter.flagged => q.flagged,
            },
          );
          final wrong = (a.attempt.wrongCount ?? 0) > 0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Summary(summary: a.attempt),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      if (wrong)
                        FilledButton.tonalIcon(
                          onPressed: _starting ? null : () => _retry(a, wrongOnly: true),
                          icon: const Icon(Icons.replay),
                          label: const Text('أعد الأخطاء فقط'),
                        ),
                      OutlinedButton.icon(
                        onPressed: _starting ? null : () => _retry(a, wrongOnly: false),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('أعد الاختبار'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in _Filter.values)
                        ChoiceChip(
                          label: Text(_filterLabels[f]!),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty) const EmptyState('لا توجد أسئلة هنا', icon: Icons.filter_alt_off_outlined),
                  for (final q in shown) _ResultCard(index: a.questions.indexOf(q) + 1, question: q),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final AttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final passed = summary.passed;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(summary.titleAr, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              percent(summary.scorePercent ?? 0),
              key: const Key('score'),
              style: text.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
            ),
            if (passed != null)
              Text(
                passed ? 'ناجح' : 'لم تبلغ علامة النجاح (${percent(summary.passingScorePercent ?? 0)})',
                style: TextStyle(color: passed ? Colors.green.shade700 : scheme.error, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _Stat(label: 'صحيحة', value: summary.correctCount ?? 0, color: Colors.green.shade700),
                _Stat(label: 'خاطئة', value: summary.wrongCount ?? 0, color: scheme.error),
                _Stat(label: 'متروكة', value: summary.skippedCount ?? 0, color: scheme.outline),
              ],
            ),
            if (summary.timeSpentMs != null) ...[
              const SizedBox(height: 8),
              Text('الوقت: ${humanDuration(summary.timeSpentMs!)}', style: text.bodySmall),
            ],
            if (summary.submittedLate) ...[
              const SizedBox(height: 8),
              Text('تم التسليم بعد انتهاء الوقت', style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
      Text(label),
    ],
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.index, required this.question});

  final int index;
  final AttemptQuestion question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = question;
    final r = q.result;
    final answered = _answered(q);
    final (IconData icon, Color color, String status) = !answered
        ? (Icons.remove_circle_outline, scheme.outline, 'متروك')
        : r?.isCorrect == true
        ? (Icons.check_circle, Colors.green.shade700, 'صحيح')
        : (Icons.cancel, scheme.error, 'خاطئ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, semanticLabel: status),
                const SizedBox(width: 8),
                Text('السؤال $index', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (q.flagged) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.flag, size: 16, color: scheme.error, semanticLabel: 'معلّم'),
                ],
                const Spacer(),
                ReportButton(type: ReportItemType.question, id: q.questionId),
              ],
            ),
            const SizedBox(height: 8),
            Text(isolateLtr(q.questionText)),
            const SizedBox(height: 8),
            if (q.type == AttemptQuestionType.written) ...[
              Text('إجابتك: ${answered ? isolateLtr(q.writtenAnswer!) : '—'}'),
              if (r?.correctAnswer != null) Text('الإجابة الصحيحة: ${isolateLtr(r!.correctAnswer!)}'),
            ] else
              for (final o in q.options)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        o.isCorrect == true
                            ? Icons.check
                            : o.id == q.selectedOptionId
                            ? Icons.close
                            : Icons.circle_outlined,
                        size: 18,
                        color: o.isCorrect == true
                            ? Colors.green.shade700
                            : o.id == q.selectedOptionId
                            ? scheme.error
                            : scheme.outlineVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isolateLtr(o.text),
                          style: TextStyle(fontWeight: o.id == q.selectedOptionId ? FontWeight.w600 : null),
                        ),
                      ),
                    ],
                  ),
                ),
            if (r?.explanation != null) ...[
              const Divider(height: 20),
              Text(isolateLtr(r!.explanation!), style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
