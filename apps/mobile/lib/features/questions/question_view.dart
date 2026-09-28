import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/form_widgets.dart';
import 'question_providers.dart';

/// One question with answer input, a server check (تحقق), then the correct answer and explanation.
/// The answer cannot change after checking (spec §15.2). Reused by practice mode in Phase 7.
class QuestionView extends ConsumerStatefulWidget {
  const QuestionView({super.key, required this.question, this.onChecked});

  final StudentQuestion question;
  final ValueChanged<CheckResult>? onChecked;

  @override
  ConsumerState<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends ConsumerState<QuestionView> {
  final _written = TextEditingController();
  String? _selected;
  CheckResult? _result;
  String? _error;
  bool _busy = false;

  StudentQuestion get q => widget.question;
  bool get _answered => q.type == StudentQuestionType.written ? _written.text.trim().isNotEmpty : _selected != null;

  @override
  void dispose() {
    _written.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(questionRepositoryProvider)
          .check(
            q.id,
            selectedOptionId: q.type == StudentQuestionType.written ? null : _selected,
            writtenAnswer: q.type == StudentQuestionType.written ? _written.text : null,
          );
      if (!mounted) return;
      setState(() => _result = result);
      widget.onChecked?.call(result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isolateLtr(q.questionText ?? ''), style: text.titleMedium?.copyWith(height: 1.6)),
        const SizedBox(height: 16),
        if (q.type == StudentQuestionType.written)
          TextField(
            key: const Key('written-answer'),
            controller: _written,
            enabled: result == null,
            decoration: const InputDecoration(labelText: 'إجابتك'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _answered && result == null ? _check() : null,
          )
        else
          for (final option in q.options ?? const <StudentOption>[]) _optionTile(option, result),
        const SizedBox(height: 16),
        ErrorBanner(_error),
        if (result == null)
          SubmitButton(label: 'تحقق', busy: _busy, onPressed: _answered ? _check : null)
        else
          AnswerFeedback(result: result, written: q.type == StudentQuestionType.written),
      ],
    );
  }

  Widget _optionTile(StudentOption option, CheckResult? result) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected == option.id;
    final isCorrect = result?.correctOptionId == option.id;
    final (Color? border, IconData icon) = switch ((result, selected, isCorrect)) {
      (null, true, _) => (scheme.primary, Icons.radio_button_checked),
      (null, false, _) => (null, Icons.radio_button_unchecked),
      (_, _, true) => (Colors.green.shade600, Icons.check_circle),
      (_, true, false) => (scheme.error, Icons.cancel),
      _ => (null, Icons.radio_button_unchecked),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border ?? scheme.outlineVariant, width: border == null ? 1 : 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: border),
        title: Text(isolateLtr(option.text)),
        selected: selected,
        onTap: result == null ? () => setState(() => _selected = option.id) : null,
      ),
    );
  }
}

/// Correct/incorrect, the correct answer (written questions) and the explanation.
class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({super.key, required this.result, required this.written});

  final CheckResult result;
  final bool written;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = result.isCorrect ? Colors.green.shade700 : scheme.error;
    return Card(
      color: color.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(result.isCorrect ? Icons.check_circle : Icons.cancel, color: color),
                const SizedBox(width: 8),
                Text(
                  result.isCorrect ? 'إجابة صحيحة' : 'إجابة خاطئة',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (written && !result.isCorrect && result.correctAnswer != null) ...[
              const SizedBox(height: 8),
              Text('الإجابة الصحيحة: ${isolateLtr(result.correctAnswer!)}'),
            ],
            if (result.explanation != null) ...[
              const SizedBox(height: 8),
              Text(isolateLtr(result.explanation!), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
