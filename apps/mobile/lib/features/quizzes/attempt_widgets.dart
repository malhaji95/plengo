import 'package:flutter/material.dart';

import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../questions/question_view.dart';

/// Question type chip, question text, then its options or the «إجابتك» field. Options show
/// correctness only when [result] is set (after grading); before that nothing reveals the answer
/// (spec §14.3).
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
    final result = widget.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionTypeChip(typeName: q.type.name),
        const SizedBox(height: 12),
        QuestionPrompt(q.questionText),
        const SizedBox(height: 16),
        if (q.type == AttemptQuestionType.written)
          WrittenAnswerField(
            controller: _written,
            enabled: widget.enabled,
            onChanged: widget.onWrite,
            onSubmitted: widget.onSubmitWritten,
          )
        else
          QuestionOptions(
            options: [for (final o in q.options) (id: o.id, text: o.text)],
            selectedId: widget.selectedOptionId,
            graded: result != null,
            isCorrect: (id) {
              final o = q.options.firstWhere((o) => o.id == id);
              return o.isCorrect ?? id == result?.correctOptionId;
            },
            onSelect: widget.enabled ? widget.onSelect : null,
          ),
      ],
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

/// Shown while the device cannot reach the server; work continues locally. An orange-soft note with
/// a cloud icon and «إعادة المحاولة».
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hue = PlengoColors.orange;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
        decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 22, color: hue.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  text,
                  style: PlengoType.sub.copyWith(color: hue.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: hue.ink,
                  minimumSize: const Size(48, 48),
                  textStyle: PlengoType.buttonSmall,
                ),
                child: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}
