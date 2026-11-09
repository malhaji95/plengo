import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/question_repository.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/ui/ui.dart';
import '../access/access_banner.dart';
import '../subjects/scope_widgets.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'question_providers.dart';
import 'question_view.dart';

export 'question_view.dart' show PracticeScreen;

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
    final s = context.surface;
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth, title: Text(title)),
      body: AsyncView(
        value: list,
        onRetry: () => ref.invalidate(questionListProvider(query)),
        data: (state) => state.items.isEmpty
            ? const PlengoEmptyState(title: 'لا توجد أسئلة هنا بعد', icon: Icons.quiz_outlined)
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 400) ref.read(questionListProvider(query).notifier).loadMore();
                  return false;
                },
                child: ContentWidthBox(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
                    children: [
                      Text(
                        '${state.accessibleCount} من ${state.totalCount} ${state.totalCount == 1 ? 'سؤال' : 'أسئلة'} متاح',
                        style: PlengoType.rowTitle.copyWith(color: s.ink, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (state.accessibleCount < state.totalCount)
                        LockedNotice(subjectId: query.subjectId, teacherTrackId: query.teacherTrackId),
                      if (state.accessible.isNotEmpty) ...[
                        PlengoButton(
                          label: 'ابدأ التدريب',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => _practice(context, state.accessible, 0),
                        ),
                        const SizedBox(height: PlengoSpace.section),
                      ],
                      for (final (i, q) in state.items.indexed)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                          child: _QuestionTile(
                            index: i + 1,
                            question: q,
                            onTap: q.locked
                                ? null
                                : () => _practice(context, state.accessible, state.accessible.indexOf(q)),
                          ),
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

/// One question of the list: its number, two lines of text (or «سؤال مقفل»), type and «مجاني»; a
/// locked question shows the «مقفل» chip and is not tappable.
class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.index, required this.question, this.onTap});

  final int index;
  final StudentQuestion question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final locked = question.locked;
    final hue = locked ? PlengoColors.red : PlengoColors.blue;
    return PlengoCard(
      radius: PlengoRadius.row,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      child: MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: hue.soft, shape: BoxShape.circle),
                child: Text('$index', style: PlengoType.chip.copyWith(color: hue.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    locked
                        ? Text('سؤال مقفل', style: PlengoType.rowTitle.copyWith(color: s.mute))
                        : Text(
                            isolateLtr(question.questionText ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: PlengoType.rowTitle.copyWith(color: s.ink, fontWeight: FontWeight.w600),
                          ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(_typeLabels[question.type]!, style: PlengoType.caption.copyWith(color: s.mute)),
                        if (question.isFree) const PlengoChip(label: 'مجاني', hue: PlengoColors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (locked) const LockedChip() else Icon(Icons.chevron_right_rounded, color: s.mute),
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
