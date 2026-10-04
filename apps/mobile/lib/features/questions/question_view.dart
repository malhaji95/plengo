import '../../app/theme.dart';
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
    final selected = _selected == option.id;
    return AnswerOptionTile(
      text: option.text,
      state: OptionState.of(graded: result != null, selected: selected, correct: result?.correctOptionId == option.id),
      onTap: result == null ? () => setState(() => _selected = option.id) : null,
    );
  }
}

/// How an answer option looks: before grading only the selection shows; after grading the correct
/// option and a wrong pick are marked with an icon and a tint, never colour alone (§14.3).
enum OptionState {
  idle,
  selected,
  correct,
  wrong;

  static OptionState of({required bool graded, required bool selected, required bool correct}) =>
      switch ((graded, selected, correct)) {
        (false, true, _) => OptionState.selected,
        (true, _, true) => OptionState.correct,
        (true, true, false) => OptionState.wrong,
        _ => OptionState.idle,
      };
}

class AnswerOptionTile extends StatelessWidget {
  const AnswerOptionTile({super.key, required this.text, required this.state, this.onTap});

  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final dark = b == Brightness.dark;
    final (Color? tint, Color? mark, IconData icon) = switch (state) {
      OptionState.idle => (null, null, Icons.radio_button_unchecked),
      OptionState.selected => (BrandColors.tintBlue, scheme.primary, Icons.radio_button_checked),
      OptionState.correct => (BrandColors.tintGreen, BrandColors.success(b), Icons.check_circle),
      OptionState.wrong => (BrandColors.tintRed, scheme.error, Icons.cancel),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: tint == null ? null : (dark ? tint.withValues(alpha: 0.16) : tint),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: mark ?? scheme.outlineVariant, width: mark == null ? 1 : 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: mark ?? scheme.outline),
        title: Text(
          isolateLtr(text),
          style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
        ),
        selected: state == OptionState.selected,
        onTap: onTap,
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
    final b = Theme.of(context).brightness;
    final color = result.isCorrect ? BrandColors.success(b) : scheme.error;
    final tint = result.isCorrect ? BrandColors.tintGreen : BrandColors.tintRed;
    return Card(
      color: b == Brightness.dark ? tint.withValues(alpha: 0.14) : tint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(color: b == Brightness.dark ? color : BrandColors.ink, fontWeight: FontWeight.bold),
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
