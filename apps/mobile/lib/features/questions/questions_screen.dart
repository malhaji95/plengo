import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/question_repository.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_banner.dart';
import '../bookmarks/bookmark_button.dart';
import '../reports/report_sheet.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'question_providers.dart';
import 'question_view.dart';

const _typeLabels = {
  StudentQuestionType.mcq: 'اختيار من متعدد',
  StudentQuestionType.trueFalse: 'صح أو خطأ',
  StudentQuestionType.written: 'إجابة مكتوبة',
};

/// Questions of a subject's general content or of a track, optionally one lesson (spec §14).
/// Locked questions show as metadata only (§8.6); free ones stay open inside a locked scope.
class QuestionsScreen extends ConsumerWidget {
  const QuestionsScreen({super.key, required this.query, required this.title});

  final QuestionQuery query;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(questionListProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: list,
        onRetry: () => ref.invalidate(questionListProvider(query)),
        data: (state) => state.items.isEmpty
            ? const EmptyState('لا توجد أسئلة هنا بعد', icon: Icons.quiz_outlined)
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 400) ref.read(questionListProvider(query).notifier).loadMore();
                  return false;
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Text(
                          '${state.accessibleCount} من ${state.totalCount} ${state.totalCount == 1 ? 'سؤال' : 'أسئلة'} متاح',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        if (state.accessibleCount < state.totalCount) const LockedNotice(),
                        if (state.accessible.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () => _practice(context, state.accessible, 0),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('ابدأ التدريب'),
                          ),
                        const SizedBox(height: 12),
                        for (final (i, q) in state.items.indexed)
                          _QuestionTile(
                            index: i + 1,
                            question: q,
                            onTap: q.locked
                                ? null
                                : () => _practice(context, state.accessible, state.accessible.indexOf(q)),
                          ),
                        if (state.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _practice(BuildContext context, List<StudentQuestion> questions, int start) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(title: title, questions: questions, initialIndex: start),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.index, required this.question, this.onTap});

  final int index;
  final StudentQuestion question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(radius: 14, child: Text('$index', style: const TextStyle(fontSize: 12))),
        title: question.locked
            ? Text('سؤال مقفل', style: TextStyle(color: scheme.outline))
            : Text(isolateLtr(question.questionText ?? ''), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([_typeLabels[question.type]!, if (question.isFree) 'مجاني'].join(' · ')),
        trailing: question.locked
            ? Icon(Icons.lock_outline, color: scheme.outline, semanticLabel: 'مقفل')
            : const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

/// Answer the accessible questions one by one: تحقق, then التالي.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.title, required this.questions, this.initialIndex = 0});

  final String title;
  final List<StudentQuestion> questions;
  final int initialIndex;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late int _index = widget.initialIndex;
  bool _checked = false;
  int _correct = 0;
  int _answered = 0;

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_index];
    final last = _index == widget.questions.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ReportButton(type: ReportItemType.question, id: q.id),
          BookmarkButton(type: BookmarkItemType.question, id: q.id),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LinearProgressIndicator(value: (_index + 1) / widget.questions.length),
              const SizedBox(height: 8),
              Text(
                'السؤال ${_index + 1} من ${widget.questions.length} · صحيحة $_correct من $_answered',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
              QuestionView(
                key: ValueKey(q.id),
                question: q,
                onChecked: (r) => setState(() {
                  _checked = true;
                  _answered++;
                  if (r.isCorrect) _correct++;
                }),
              ),
              const SizedBox(height: 16),
              if (_checked)
                last
                    ? OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إنهاء'))
                    : FilledButton(
                        onPressed: () => setState(() {
                          _index++;
                          _checked = false;
                        }),
                        child: const Text('التالي'),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Route entry for `/subjects/:id/questions[?lessonId=]`: titles come from the (cached) outline.
class SubjectQuestionsRoute extends ConsumerWidget {
  const SubjectQuestionsRoute({super.key, required this.subjectId, this.unitId, this.lessonId});

  final String subjectId;
  final String? unitId;
  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    final lessons = [...?outline?.lessons, ...?outline?.units.expand((u) => u.lessons)];
    final lessonTitle = lessons.where((l) => l.id == lessonId).firstOrNull?.titleAr;
    return QuestionsScreen(
      query: (subjectId: subjectId, teacherTrackId: null, unitId: unitId, lessonId: lessonId),
      title: lessonTitle ?? (outline != null ? 'أسئلة ${outline.subject.nameAr}' : 'الأسئلة'),
    );
  }
}

/// Route entry for `/tracks/:id/questions`.
class TrackQuestionsRoute extends ConsumerWidget {
  const TrackQuestionsRoute({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    return detail.when(
      data: (d) => QuestionsScreen(
        query: (subjectId: d.subject.id, teacherTrackId: trackId, unitId: null, lessonId: null),
        title: d.track.titleAr,
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(trackProvider(trackId)),
          data: (_) => const SizedBox(),
        ),
      ),
    );
  }
}
