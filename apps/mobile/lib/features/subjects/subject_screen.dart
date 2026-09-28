import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_banner.dart';
import '../learning/scope_learning.dart';
import '../questions/question_providers.dart';
import 'catalog_providers.dart';
import '../offline/download_widgets.dart';

/// A subject's outline: optional units with their lessons, then lessons directly under the subject.
/// Questions, decks, quizzes, random practice and progress appear here from Phase 5 on.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: Text(outline.value?.subject.nameAr ?? '')),
      body: AsyncView(
        value: outline,
        onRetry: () => ref.invalidate(subjectOutlineProvider(subjectId)),
        data: (o) => _OutlineView(outline: o),
      ),
    );
  }
}

class _OutlineView extends ConsumerWidget {
  const _OutlineView({required this.outline});

  final SubjectOutline outline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(progressProvider((subjectId: outline.subject.id, teacherTrackId: null))).value;
    int? unitPercent(String id) => progress?.units.where((u) => u.unitId == id).firstOrNull?.completionPercent;
    final empty =
        outline.units.isEmpty &&
        outline.lessons.isEmpty &&
        outline.tracks.isEmpty &&
        outline.questionCount.total == 0 &&
        outline.deckCount.total == 0 &&
        outline.quizCount.total == 0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (outline.subject.description != null) ...[
              Text(outline.subject.description!, style: text.bodyMedium),
              const SizedBox(height: 16),
            ],
            ScopeAccessBanner(access: outline.access),
            ScopeLearning(
              subjectId: outline.subject.id,
              quizCount: outline.quizCount,
              questionCount: outline.questionCount,
              quizzesPath: '${Routes.subjects}/${outline.subject.id}/quizzes',
            ),
            OfflineDownloadTile(scope: (subjectId: outline.subject.id, teacherTrackId: null), label: 'تحميل الكل'),
            if (outline.deckCount.total > 0)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.style_outlined),
                  title: const Text('البطاقات التعليمية'),
                  subtitle: Text(_deckText(outline.deckCount)),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.go('${Routes.subjects}/${outline.subject.id}/decks'),
                ),
              ),
            if (outline.questionCount.total > 0)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.quiz_outlined),
                  title: const Text('بنك الأسئلة'),
                  subtitle: Text(_countText(outline.questionCount)),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.go('${Routes.subjects}/${outline.subject.id}/questions'),
                ),
              ),
            if (empty) const EmptyState('محتوى هذه المادة قيد الإعداد', icon: Icons.hourglass_empty),
            for (final (i, unit) in outline.units.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  key: PageStorageKey(unit.id),
                  initiallyExpanded: i == 0,
                  leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: text.labelMedium)),
                  title: Text(unit.titleAr, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    [
                      lessonCountLabel(unit.lessons.length),
                      if ((unitPercent(unit.id) ?? 0) > 0) 'أنجزت ${percent(unitPercent(unit.id)!)}',
                    ].join(' · '),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: OfflineDownloadTile(
                        scope: (subjectId: outline.subject.id, teacherTrackId: null),
                        unitId: unit.id,
                        label: 'تحميل الوحدة',
                      ),
                    ),
                    if (unit.lessons.isEmpty) const ListTile(title: Text('لا توجد دروس في هذه الوحدة بعد')),
                    for (final lesson in unit.lessons) _LessonTile(lesson: lesson, subjectId: outline.subject.id),
                  ],
                ),
              ),
            if (outline.lessons.isNotEmpty) ...[
              if (outline.units.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('دروس عامة', style: text.titleSmall),
                const SizedBox(height: 8),
              ],
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final lesson in outline.lessons) _LessonTile(lesson: lesson, subjectId: outline.subject.id),
                  ],
                ),
              ),
            ],
            if (outline.tracks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('مسارات المدرسين', style: text.titleSmall),
              const SizedBox(height: 8),
              for (final track in outline.tracks)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: NetworkAvatar(url: track.teacherPhotoUrl, name: track.teacherNameAr),
                    title: Text(track.titleAr),
                    subtitle: Text(track.teacherNameAr),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          track.hasAccess ? Icons.lock_open : Icons.lock_outline,
                          size: 18,
                          semanticLabel: track.hasAccess ? 'متاح' : 'مقفل',
                        ),
                        const Icon(Icons.chevron_left),
                      ],
                    ),
                    onTap: () => context.go('${Routes.tracks}/${track.id}'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.subjectId});

  final Lesson lesson;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.article_outlined),
      title: Text(lesson.titleAr),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => context.go('${Routes.subjects}/$subjectId/questions?lessonId=${lesson.id}'),
    );
  }
}

String _countText(ContentCount c) =>
    c.free > 0 ? '${questionCountLabel(c.total)} · ${c.free} مجاني' : questionCountLabel(c.total);

/// Arabic count agreement: درس واحد، درسان، 3–10 دروس، 11+ درساً.
String lessonCountLabel(int n) => switch (n) {
  0 => 'لا دروس بعد',
  1 => 'درس واحد',
  2 => 'درسان',
  >= 3 && <= 10 => '$n دروس',
  _ => '$n درساً',
};

String _deckText(ContentCount c) {
  final decks = c.total == 1
      ? 'مجموعة واحدة'
      : c.total == 2
      ? 'مجموعتان'
      : '${c.total} مجموعات';
  return c.free > 0 ? '$decks · ${c.free} مجانية' : decks;
}
