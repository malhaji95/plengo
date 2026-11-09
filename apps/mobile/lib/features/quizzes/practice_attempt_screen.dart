import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../questions/question_view.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

/// Practice mode (spec §15.2): answer → تحقق → the server grades and explains → متابعة. An answer
/// cannot change after checking. Resuming continues at the first unchecked question.
class PracticeAttemptScreen extends ConsumerStatefulWidget {
  const PracticeAttemptScreen({super.key, required this.attempt});

  final Attempt attempt;

  /// Exit sheet title: a practice attempt is resumable (DECISIONS #13).
  static const exitTitle = 'تقدّمك محفوظ';

  @override
  ConsumerState<PracticeAttemptScreen> createState() => _PracticeAttemptScreenState();
}

class _PracticeAttemptScreenState extends ConsumerState<PracticeAttemptScreen> {
  late final List<AttemptQuestion> _questions = [...widget.attempt.questions];
  late final Map<String, CheckResult> _results = {
    for (final q in _questions)
      if (q.result != null) q.questionId: q.result!,
  };
  late final Map<String, String?> _selected = {for (final q in _questions) q.questionId: q.selectedOptionId};
  late final Map<String, String> _written = {
    for (final q in _questions)
      if (q.writtenAnswer != null) q.questionId: q.writtenAnswer!,
  };
  late int _index = () {
    final i = _questions.indexWhere((q) => q.result == null);
    return i < 0 ? _questions.length - 1 : i;
  }();
  bool _busy = false;
  String? _error;
  final _shownAt = Stopwatch()..start();

  /// Correct answers in a row checked in this session (DECISIONS #10).
  int _run = 0;

  String get _id => widget.attempt.attempt.id;
  AttemptQuestion get _q => _questions[_index];
  bool get _isWritten => _q.type == AttemptQuestionType.written;
  bool get _hasAnswer =>
      _isWritten ? (_written[_q.questionId]?.trim().isNotEmpty ?? false) : _selected[_q.questionId] != null;
  int get _correct => _results.values.where((r) => r.isCorrect).length;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(learningRepositoryProvider)
          .check(
            _id,
            _q.questionId,
            CheckAttemptAnswerRequest(
              selectedOptionId: _isWritten ? null : _selected[_q.questionId],
              writtenAnswer: _isWritten ? _written[_q.questionId] : null,
              timeSpentMs: _shownAt.elapsedMilliseconds,
            ),
          );
      if (mounted) {
        setState(() {
          _results[_q.questionId] = result;
          _run = result.isCorrect ? _run + 1 : 0;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'NETWORK_ERROR' ? 'التحقق يحتاج إلى اتصال بالإنترنت' : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref.read(learningRepositoryProvider).submit(_id, const SubmitAttemptRequest(answers: []));
      if (!mounted) return;
      ref.invalidate(attemptProvider(_id));
      context.pushReplacement('/attempts/$_id/results');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    final next = _questions.indexWhere((q) => !_results.containsKey(q.questionId));
    final leave = await confirmLeavePractice(
      context,
      title: PracticeAttemptScreen.exitTitle,
      message: next < 0 ? null : 'يمكنك المتابعة من السؤال ${next + 1} في أي وقت.',
    );
    if (leave && mounted) leaveFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final result = _results[_q.questionId];
    final last = _index == _questions.length - 1;
    final correctText = result == null
        ? null
        : _q.options.where((o) => o.id == result.correctOptionId).firstOrNull?.text ?? result.correctAnswer;
    // Early finish (spec §15.2): submit now and see the results.
    final finishEarly = PlengoButton(
      label: 'إنهاء التدريب',
      variant: PlengoButtonVariant.ghost,
      size: PlengoButtonSize.small,
      expand: true,
      onPressed: _busy ? null : _finish,
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PracticeHeader(
              position: _index + 1,
              total: _questions.length,
              correct: _correct,
              checked: _results.length,
              progress: (_index + (result == null ? 0 : 1)) / _questions.length,
              onExit: _exit,
              questionId: _q.questionId,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
                  child: ListView(
                    key: ValueKey(_q.questionId),
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
                    children: [
                      if (result != null && result.isCorrect && _run >= 3) ...[
                        CorrectStreakChip(count: _run),
                        const SizedBox(height: 12),
                      ],
                      Text(widget.attempt.attempt.titleAr, style: PlengoType.caption.copyWith(color: s.mute)),
                      const SizedBox(height: 6),
                      AttemptQuestionBody(
                        key: ValueKey(_q.questionId),
                        question: _q,
                        selectedOptionId: _selected[_q.questionId],
                        writtenAnswer: _written[_q.questionId],
                        enabled: result == null && !_busy,
                        result: result,
                        onSelect: (id) => setState(() => _selected[_q.questionId] = id),
                        onWrite: (text) => setState(() => _written[_q.questionId] = text),
                        onSubmitWritten: _hasAnswer && result == null ? _check : null,
                      ),
                      if (result != null && _error != null) ...[const SizedBox(height: 12), InlineError(_error)],
                    ],
                  ),
                ),
              ),
            ),
            if (result == null)
              CheckBar(
                hasAnswer: _hasAnswer,
                busy: _busy,
                written: _isWritten,
                error: _error,
                onCheck: _check,
                extra: finishEarly,
              )
            else
              AnswerFeedbackPanel(
                result: result,
                questionId: _q.questionId,
                correctAnswerText: correctText,
                // Attempt answers are graded on the server, which records wrong ones in the mistake bank.
                addedToMistakes: true,
                actionLabel: last ? 'عرض النتيجة' : null,
                onContinue: _busy
                    ? null
                    : last
                    ? _finish
                    : () => setState(() {
                        _index++;
                        _error = null;
                        _shownAt.reset();
                      }),
              ),
          ],
        ),
      ),
    );
  }
}
