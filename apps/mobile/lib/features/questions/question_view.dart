import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../bookmarks/bookmark_button.dart';
import '../reports/report_sheet.dart';
import 'question_providers.dart';

// ---------------------------------------------------------------------------------------------
// Shared question widgets (V-Question): used by question-bank practice, quiz practice attempts,
// exam mode and random practice.
// ---------------------------------------------------------------------------------------------

const _typeLabels = {'mcq': 'اختيار من متعدد', 'trueFalse': 'صح أو خطأ', 'written': 'إجابة مكتوبة'};

/// The Arabic label of a question type by its enum name (`mcq`, `trueFalse`, `written`).
String questionTypeLabel(String typeName) => _typeLabels[typeName] ?? '';

/// «اختيار من متعدد» / «صح أو خطأ» / «إجابة مكتوبة» above the question.
class QuestionTypeChip extends StatelessWidget {
  const QuestionTypeChip({super.key, required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: PlengoChip(label: questionTypeLabel(typeName), hue: PlengoColors.blue),
  );
}

/// The question text, 21/700; formulas and Latin runs stay left-to-right.
class QuestionPrompt extends StatelessWidget {
  const QuestionPrompt(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(isolateLtr(text), style: PlengoType.question.copyWith(color: context.surface.ink)),
  );
}

/// How an option looks: before grading only the selection shows; after grading the correct option is
/// green «✓ صحيحة», a wrong pick red «✗ إجابتك» and the rest dimmed (spec §14.3, §4).
AnswerState answerStateOf({required bool graded, required bool selected, required bool correct}) =>
    switch ((graded, selected, correct)) {
      (false, true, _) => AnswerState.selected,
      (false, false, _) => AnswerState.normal,
      (true, _, true) => AnswerState.correct,
      (true, true, false) => AnswerState.wrong,
      (true, false, false) => AnswerState.dimmed,
    };

/// One answer option of a question: id and text.
typedef QuestionChoice = ({String id, String text});

/// The option tiles (أ ب ج د). [correctId] is only known after grading ([graded]).
class QuestionOptions extends StatelessWidget {
  const QuestionOptions({
    super.key,
    required this.options,
    required this.selectedId,
    required this.graded,
    this.isCorrect,
    this.onSelect,
  });

  final List<QuestionChoice> options;
  final String? selectedId;
  final bool graded;

  /// Whether an option is the right one; only asked when [graded].
  final bool Function(String optionId)? isCorrect;

  /// Null when the answer can no longer change.
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'الخيارات',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in options.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          AnswerOption(
            index: i,
            text: isolateLtr(o.text),
            state: answerStateOf(
              graded: graded,
              selected: o.id == selectedId,
              correct: graded && (isCorrect?.call(o.id) ?? false),
            ),
            onTap: onSelect == null ? null : () => onSelect!(o.id),
          ),
        ],
      ],
    ),
  );
}

/// The large «إجابتك» field for written questions.
class WrittenAnswerField extends StatelessWidget {
  const WrittenAnswerField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PlengoRadius.input),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text('إجابتك', style: PlengoType.rowTitle.copyWith(color: s.ink)),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('written-answer'),
          controller: controller,
          enabled: enabled,
          minLines: 2,
          maxLines: 6,
          textInputAction: TextInputAction.done,
          style: PlengoType.body.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: s.ink),
          decoration: InputDecoration(
            semanticCounterText: '',
            labelText: null,
            hintText: 'اكتب إجابتك هنا',
            hintStyle: PlengoType.body.copyWith(color: s.mute),
            filled: true,
            fillColor: s.card,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: border(s.line),
            disabledBorder: border(s.line),
            focusedBorder: border(s.action),
          ),
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
        ),
      ],
    );
  }
}

/// «N إجابات صحيحة متتالية!» with Arabic count agreement (11+ takes the singular).
String correctStreakLabel(int n) => n <= 10 ? '$n إجابات صحيحة متتالية!' : '$n إجابة صحيحة متتالية!';

/// The orange in-session streak chip (DECISIONS #10), shown at ≥ 3 correct answers in a row.
class CorrectStreakChip extends StatelessWidget {
  const CorrectStreakChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Semantics(
      liveRegion: true,
      child: PlengoChip(
        key: const Key('correct-streak'),
        label: correctStreakLabel(count),
        hue: PlengoColors.orange,
        icon: Icons.local_fire_department_rounded,
      ),
    ),
  );
}

/// A red-soft line with an alert icon (check or submit errors).
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final red = PlengoColors.red;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: red.soft, borderRadius: BorderRadius.circular(PlengoRadius.input)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: red.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message!,
                style: PlengoType.sub.copyWith(color: red.ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 48 × 48 soft square around a stock icon button (e.g. [BookmarkButton]) so the app bar matches.
class SoftSlot extends StatelessWidget {
  const SoftSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      width: PlengoSpace.minTouch,
      height: PlengoSpace.minTouch,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: BorderRadius.circular(PlengoRadius.iconButton),
        border: s.isDark ? Border.all(color: s.line) : null,
        boxShadow: s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: s.ink),
        child: child,
      ),
    );
  }
}

/// The V-Question header: ✕, a green progress bar labelled «السؤال 3 من 10 · صحيحة 2 من 3», the
/// report flag (hidden when reports are off) and the bookmark.
class PracticeHeader extends StatelessWidget {
  const PracticeHeader({
    super.key,
    required this.position,
    required this.total,
    required this.correct,
    required this.checked,
    required this.progress,
    required this.onExit,
    required this.questionId,
  });

  /// 1-based number of the current question.
  final int position;
  final int total;
  final int correct;
  final int checked;

  /// 0–1.
  final double progress;
  final VoidCallback onExit;
  final String questionId;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 4),
      child: Row(
        children: [
          PlengoIconButton(icon: Icons.close_rounded, tooltip: 'خروج', onPressed: onExit),
          const SizedBox(width: 8),
          Expanded(
            child: PlengoProgressBar(
              value: progress,
              label: 'السؤال $position من $total · صحيحة $correct من $checked',
              color: PlengoColors.green.base,
              labelColor: s.ink,
              labelBelow: true,
            ),
          ),
          const SizedBox(width: 8),
          ReportButton(type: ReportItemType.question, id: questionId),
          const SizedBox(width: 6),
          SoftSlot(
            child: BookmarkButton(type: BookmarkItemType.question, id: questionId),
          ),
        ],
      ),
    );
  }
}

/// The bottom bar before checking: disabled «اختر إجابة» until there is an answer, then «تحقق».
class CheckBar extends StatelessWidget {
  const CheckBar({
    super.key,
    required this.hasAnswer,
    required this.busy,
    required this.onCheck,
    this.written = false,
    this.error,
    this.extra,
  });

  final bool hasAnswer;
  final bool busy;
  final VoidCallback onCheck;
  final bool written;
  final String? error;

  /// Below the button (e.g. «إنهاء التدريب»).
  final Widget? extra;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[InlineError(error), const SizedBox(height: 10)],
              PlengoButton(
                label: hasAnswer ? 'تحقق' : (written ? 'اكتب إجابتك' : 'اختر إجابة'),
                busy: busy,
                onPressed: hasAnswer && !busy ? onCheck : null,
              ),
              ?extra,
            ],
          ),
        ),
      ),
    );
  }
}

/// The feedback panel for a graded answer (spec §4): «أحسنت!» or «ليست الإجابة الصحيحة», the correct
/// answer, the explanation and the report flag. [addedToMistakes] shows «أضفناه إلى مراجعة الأخطاء»
/// on a wrong answer; pass it only where the server really records the mistake.
class AnswerFeedbackPanel extends StatelessWidget {
  const AnswerFeedbackPanel({
    super.key,
    required this.result,
    required this.questionId,
    required this.onContinue,
    this.correctAnswerText,
    this.addedToMistakes = false,
    this.actionLabel,
  });

  final CheckResult result;
  final String questionId;
  final VoidCallback? onContinue;

  /// The right answer in words: the correct option's text, or the model answer of a written question.
  final String? correctAnswerText;
  final bool addedToMistakes;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    final hue = ok ? PlengoColors.green : PlengoColors.red;
    final answer = correctAnswerText ?? result.correctAnswer;
    return FeedbackPanel(
      key: ValueKey('feedback-$questionId'),
      correct: ok,
      onContinue: onContinue,
      actionLabel: actionLabel,
      correctAnswer: answer == null ? null : Text(isolateLtr(answer)),
      explanation: result.explanation == null ? null : Text(isolateLtr(result.explanation!)),
      note: addedToMistakes ? FeedbackPanel.mistakesNote : null,
      reportAction: ReportButton(type: ReportItemType.question, id: questionId, soft: false, color: hue.ink),
    );
  }
}

/// Leaves a full-screen flow: back to where it was opened from, else Home.
void leaveFlow(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    GoRouter.maybeOf(context)?.go(Routes.home);
  }
}

/// The practice exit sheet (DECISIONS #13). True when the student chose «خروج».
Future<bool> confirmLeavePractice(BuildContext context, {required String title, String? message}) async {
  final stay = await showConfirmSheet(
    context,
    title: title,
    message: message,
    icon: Icons.bookmark_added_rounded,
    hue: PlengoColors.blue,
    primaryLabel: 'واصل التدريب',
    secondaryLabel: 'خروج',
  );
  return stay == false;
}

// ---------------------------------------------------------------------------------------------
// Question-bank practice
// ---------------------------------------------------------------------------------------------

/// Answer the accessible questions one by one: تحقق, the server (or a downloaded pack) grades and
/// explains, then متابعة. The answer cannot change after checking (spec §15.2).
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key, required this.title, required this.questions, this.initialIndex = 0});

  final String title;
  final List<StudentQuestion> questions;
  final int initialIndex;

  /// Exit sheet copy: question-bank practice is not resumable (DECISIONS #13).
  static const exitTitle = 'الخروج من التدريب؟';
  static const exitMessage = 'تُحسب إجاباتك في هدفك اليومي، وعند العودة يبدأ التدريب من جديد.';

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late int _index = widget.initialIndex;
  int _correct = 0;
  int _answered = 0;

  /// Correct answers in a row in this session (DECISIONS #10).
  int _run = 0;

  final _written = TextEditingController();
  String? _selected;
  CheckResult? _result;
  String? _error;
  bool _busy = false;

  StudentQuestion get q => widget.questions[_index];
  bool get _isWritten => q.type == StudentQuestionType.written;
  bool get _hasAnswer => _isWritten ? _written.text.trim().isNotEmpty : _selected != null;
  bool get _last => _index == widget.questions.length - 1;

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
            selectedOptionId: _isWritten ? null : _selected,
            writtenAnswer: _isWritten ? _written.text : null,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _answered++;
        if (result.isCorrect) {
          _correct++;
          _run++;
        } else {
          _run = 0;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _result = null;
      _error = null;
      _written.clear();
    });
  }

  Future<void> _exit() async {
    final leave = await confirmLeavePractice(
      context,
      title: PracticeScreen.exitTitle,
      message: PracticeScreen.exitMessage,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final total = widget.questions.length;
    final options = q.options ?? const <StudentOption>[];
    final correctText = result == null
        ? null
        : options.where((o) => o.id == result.correctOptionId).firstOrNull?.text ?? result.correctAnswer;
    // Android back / iOS swipe open the same exit sheet as ✕: leaving never discards silently (§5).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PracticeHeader(
                position: _index + 1,
                total: total,
                correct: _correct,
                checked: _answered,
                progress: (_index + (result == null ? 0 : 1)) / total,
                onExit: _exit,
                questionId: q.id,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
                    child: ListView(
                      key: ValueKey(q.id),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
                      children: [
                        if (result != null && result.isCorrect && _run >= 3) ...[
                          CorrectStreakChip(count: _run),
                          const SizedBox(height: 12),
                        ],
                        Text(widget.title, style: PlengoType.caption.copyWith(color: context.surface.mute)),
                        const SizedBox(height: 6),
                        QuestionTypeChip(typeName: q.type.name),
                        const SizedBox(height: 12),
                        QuestionPrompt(q.questionText ?? ''),
                        const SizedBox(height: 16),
                        if (_isWritten)
                          WrittenAnswerField(
                            controller: _written,
                            enabled: result == null && !_busy,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _hasAnswer && result == null && !_busy ? _check : null,
                          )
                        else
                          QuestionOptions(
                            options: [for (final o in options) (id: o.id, text: o.text)],
                            selectedId: _selected,
                            graded: result != null,
                            isCorrect: (id) => id == result?.correctOptionId,
                            onSelect: result == null && !_busy ? (id) => setState(() => _selected = id) : null,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (result == null)
                CheckBar(hasAnswer: _hasAnswer, busy: _busy, written: _isWritten, error: _error, onCheck: _check)
              else
                AnswerFeedbackPanel(
                  result: result,
                  questionId: q.id,
                  correctAnswerText: correctText,
                  // Question-bank checks are not recorded in the mistake bank (only attempt answers are).
                  addedToMistakes: false,
                  actionLabel: _last ? 'إنهاء' : null,
                  onContinue: _next,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
