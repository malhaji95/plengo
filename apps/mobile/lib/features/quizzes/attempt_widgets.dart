import 'package:flutter/material.dart';

import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';

/// Question text plus its options or a text field. Options show correctness only when [result]
/// is set (after grading); before that nothing reveals the answer (spec §14.3).
class AttemptQuestionBody extends StatefulWidget {
  const AttemptQuestionBody({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.writtenAnswer,
    required this.enabled,
    this.result,
    this.onSelect,
    this.onWrite,
    this.onSubmitWritten,
  });

  final AttemptQuestion question;
  final String? selectedOptionId;
  final String? writtenAnswer;
  final bool enabled;
  final CheckResult? result;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onWrite;
  final VoidCallback? onSubmitWritten;

  @override
  State<AttemptQuestionBody> createState() => _AttemptQuestionBodyState();
}

class _AttemptQuestionBodyState extends State<AttemptQuestionBody> {
  late final _written = TextEditingController(text: widget.writtenAnswer ?? '');

  @override
  void dispose() {
    _written.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isolateLtr(q.questionText), style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.6)),
        const SizedBox(height: 16),
        if (q.type == AttemptQuestionType.written)
          TextField(
            key: const Key('written-answer'),
            controller: _written,
            enabled: widget.enabled,
            decoration: const InputDecoration(labelText: 'إجابتك'),
            onChanged: widget.onWrite,
            onSubmitted: (_) => widget.onSubmitWritten?.call(),
          )
        else
          for (final option in q.options) _option(option),
      ],
    );
  }

  Widget _option(AttemptOption option) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selectedOptionId == option.id;
    final graded = widget.result != null;
    final correct = graded && (option.isCorrect ?? option.id == widget.result!.correctOptionId);
    final (Color? border, IconData icon) = switch ((graded, selected, correct)) {
      (false, true, _) => (scheme.primary, Icons.radio_button_checked),
      (false, false, _) => (null, Icons.radio_button_unchecked),
      (true, _, true) => (Colors.green.shade600, Icons.check_circle),
      (true, true, false) => (scheme.error, Icons.cancel),
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
        onTap: widget.enabled ? () => widget.onSelect?.call(option.id) : null,
      ),
    );
  }
}

/// "12:05" style countdown text (always LTR digits).
String formatDuration(int ms) {
  final total = (ms / 1000).ceil().clamp(0, 1 << 31);
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// A short Arabic duration for summaries: "3 د 20 ث".
String humanDuration(int ms) {
  final s = (ms / 1000).round();
  if (s < 60) return '$s ث';
  final m = s ~/ 60;
  if (m < 60) return '$m د ${s % 60} ث';
  return '${m ~/ 60} س ${m % 60} د';
}

/// Shown while the device cannot reach the server; work continues locally.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.secondaryContainer,
      leading: const Icon(Icons.cloud_off_outlined),
      content: Text(text),
      actions: [if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))],
    );
  }
}
