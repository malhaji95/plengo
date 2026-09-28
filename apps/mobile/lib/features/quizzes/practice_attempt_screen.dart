import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/form_widgets.dart';
import '../bookmarks/bookmark_button.dart';
import '../questions/question_view.dart';
import 'attempt_widgets.dart';
import 'quiz_providers.dart';

/// Practice mode (spec §15.2): answer → تحقق → the server grades and explains → التالي. An answer
/// cannot change after checking. Resuming continues at the first unchecked question.
class PracticeAttemptScreen extends ConsumerStatefulWidget {
  const PracticeAttemptScreen({super.key, required this.attempt});

  final Attempt attempt;

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
      if (mounted) setState(() => _results[_q.questionId] = result);
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

  @override
  Widget build(BuildContext context) {
    final result = _results[_q.questionId];
    final last = _index == _questions.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attempt.attempt.titleAr),
        actions: [
          BookmarkButton(type: BookmarkItemType.question, id: _q.questionId),
          TextButton(onPressed: _busy ? null : _finish, child: const Text('إنهاء')),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LinearProgressIndicator(value: (_index + 1) / _questions.length),
              const SizedBox(height: 8),
              Text(
                'السؤال ${_index + 1} من ${_questions.length} · صحيحة $_correct من ${_results.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              ErrorBanner(_error),
              if (result == null)
                SubmitButton(label: 'تحقق', busy: _busy, onPressed: _hasAnswer ? _check : null)
              else ...[
                AnswerFeedback(result: result, written: _isWritten),
                const SizedBox(height: 16),
                last
                    ? FilledButton(onPressed: _busy ? null : _finish, child: const Text('عرض النتيجة'))
                    : FilledButton(
                        onPressed: () => setState(() {
                          _index++;
                          _shownAt.reset();
                        }),
                        child: const Text('التالي'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
