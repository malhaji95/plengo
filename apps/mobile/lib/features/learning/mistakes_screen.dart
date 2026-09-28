import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../quizzes/quiz_providers.dart';

final mistakesProvider = FutureProvider.autoDispose.family<MistakeList, MistakeFilterStatus>(
  (ref, status) => ref.watch(learningRepositoryProvider).mistakes(status: status),
);

/// Mistake bank (مراجعة الأخطاء, spec §16.1): wrong answers grouped by subject and unit, with
/// "اختبر أخطائي". Questions the student can no longer open are hidden by the server.
class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  var _status = MistakeFilterStatus.active;
  String? _subjectId;

  Future<void> _test(MistakeList list) async {
    var count = list.activeCount.clamp(1, 20).toDouble();
    var mode = StartAttemptRequestMode.practice;
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('اختبر أخطائي', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text('عدد الأسئلة: ${count.round()}'),
                if (list.activeCount > 1)
                  Slider(
                    value: count,
                    min: 1,
                    max: list.activeCount.clamp(1, 100).toDouble(),
                    onChanged: (v) => setSheet(() => count = v),
                  ),
                SegmentedButton<StartAttemptRequestMode>(
                  segments: const [
                    ButtonSegment(value: StartAttemptRequestMode.practice, label: Text('تدريب')),
                    ButtonSegment(value: StartAttemptRequestMode.exam, label: Text('امتحان')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => setSheet(() => mode = s.first),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ابدأ')),
              ],
            ),
          ),
        ),
      ),
    );
    if (go != true || !mounted) return;
    try {
      final a = await startAttempt(
        ref.read(learningRepositoryProvider),
        source: StartAttemptRequestSource.mistakes,
        mode: mode,
        filters: AttemptFilters(subjectId: _subjectId, count: count.round()),
      );
      if (!mounted) return;
      await context.push('/attempts/${a.attempt.id}');
      ref.invalidate(mistakesProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mistakes = ref.watch(mistakesProvider(_status));
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الأخطاء')),
      body: AsyncView(
        value: mistakes,
        onRetry: () => ref.invalidate(mistakesProvider(_status)),
        data: (list) {
          final subjects = <String, String>{for (final m in list.items) m.subjectId: m.subjectNameAr};
          final shown = list.items.where((m) => _subjectId == null || m.subjectId == _subjectId).toList();
          // Group by subject, then unit (or the lesson directly under the subject).
          final groups = <String, List<Mistake>>{};
          for (final m in shown) {
            final key = [
              if (_subjectId == null) m.subjectNameAr,
              if (m.trackTitleAr != null) m.trackTitleAr!,
              m.unitNameAr ?? m.lessonNameAr ?? 'أسئلة عامة',
            ].join(' · ');
            (groups[key] ??= []).add(m);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<MistakeFilterStatus>(
                segments: [
                  ButtonSegment(value: MistakeFilterStatus.active, label: Text('نشطة (${list.activeCount})')),
                  ButtonSegment(value: MistakeFilterStatus.mastered, label: Text('متقنة (${list.masteredCount})')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: 12),
              if (subjects.length > 1)
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('كل المواد'),
                      selected: _subjectId == null,
                      onSelected: (_) => setState(() => _subjectId = null),
                    ),
                    for (final MapEntry(key: id, value: name) in subjects.entries)
                      ChoiceChip(
                        label: Text(name),
                        selected: _subjectId == id,
                        onSelected: (_) => setState(() => _subjectId = id),
                      ),
                  ],
                ),
              if (_status == MistakeFilterStatus.active && shown.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _test(list),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('اختبر أخطائي'),
                ),
                const SizedBox(height: 4),
                Text(
                  'يُتقن السؤال بعد ${list.masteryStreak} إجابات صحيحة متتالية',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              if (shown.isEmpty)
                EmptyState(
                  _status == MistakeFilterStatus.active ? 'لا أخطاء لمراجعتها 🎉' : 'لا أسئلة متقنة بعد',
                  icon: Icons.task_alt,
                ),
              for (final MapEntry(key: title, value: items) in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(title, style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final m in items) _MistakeTile(mistake: m),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MistakeTile extends ConsumerWidget {
  const _MistakeTile({required this.mistake});

  final Mistake mistake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = mistake;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(isolateLtr(m.questionText), maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            'أخطأت ${m.wrongCount} ${m.wrongCount == 1 ? 'مرة' : 'مرات'}',
            if (m.correctStreak > 0) 'صحيحة متتالية: ${m.correctStreak}',
          ].join(' · '),
        ),
        onTap: m.lessonId != null
            ? () => context.go('${Routes.subjects}/${m.subjectId}/questions?lessonId=${m.lessonId}')
            : null,
        trailing: m.status == MistakeStatus.active
            ? IconButton(
                tooltip: 'إزالة من الأخطاء',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await ref.read(learningRepositoryProvider).removeMistake(m.questionId);
                    ref.invalidate(mistakesProvider);
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
              )
            : null,
      ),
    );
  }
}
