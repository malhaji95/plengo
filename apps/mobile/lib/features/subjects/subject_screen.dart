import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/ui_kit.dart';

import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_banner.dart';
import '../learning/scope_learning.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final id = outline.subject.id;
    final progress = ref.watch(progressProvider((subjectId: id, teacherTrackId: null))).value;
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            ScopeHero(title: outline.subject.nameAr, subtitle: outline.subject.description, subjectId: id),
            ScopeAccessBanner(access: outline.access),
            ScopeLearning(
              subjectId: id,
              quizCount: outline.quizCount,
              questionCount: outline.questionCount,
              quizzesPath: '${Routes.subjects}/$id/quizzes',
              deckCount: outline.deckCount,
              decksPath: '${Routes.subjects}/$id/decks',
              questionsPath: '${Routes.subjects}/$id/questions',
            ),
            OfflineDownloadTile(scope: (subjectId: id, teacherTrackId: null), label: 'تحميل الكل'),
            if (empty) const EmptyState('محتوى هذه المادة قيد الإعداد', icon: Icons.hourglass_empty),
            if (outline.units.isNotEmpty) const SectionHeader('الوحدات', top: 12),
            for (final (i, unit) in outline.units.indexed)
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  key: PageStorageKey(unit.id),
                  initiallyExpanded: i == 0,
                  leading: _UnitNumber(number: i + 1, done: (unitPercent(unit.id) ?? 0) >= 100),
                  title: Text(unit.titleAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      lessonCountLabel(unit.lessons.length),
                      if ((unitPercent(unit.id) ?? 0) > 0) 'أنجزت ${percent(unitPercent(unit.id)!)}',
                    ].join(' · '),
                  ),
                  children: [
                    if ((unitPercent(unit.id) ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LinearProgressIndicator(value: unitPercent(unit.id)! / 100),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: OfflineDownloadTile(
                        scope: (subjectId: id, teacherTrackId: null),
                        unitId: unit.id,
                        label: 'تحميل الوحدة',
                      ),
                    ),
                    if (unit.lessons.isEmpty) const ListTile(title: Text('لا توجد دروس في هذه الوحدة بعد')),
                    for (final lesson in unit.lessons) _LessonTile(lesson: lesson, subjectId: id),
                  ],
                ),
              ),
            if (outline.lessons.isNotEmpty) ...[
              if (outline.units.isNotEmpty) const SectionHeader('دروس عامة', top: 12),
              Card(
                child: Column(
                  children: [for (final lesson in outline.lessons) _LessonTile(lesson: lesson, subjectId: id)],
                ),
              ),
            ],
            if (outline.tracks.isNotEmpty) ...[
              const SectionHeader('مسارات المدرسين', top: 12),
              for (final track in outline.tracks)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: NetworkAvatar(url: track.teacherPhotoUrl, name: track.teacherNameAr, radius: 22),
                    title: Text(track.titleAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(track.teacherNameAr),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AccessChip(open: track.hasAccess),
                        Icon(Icons.chevron_left, color: scheme.onSurfaceVariant),
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

/// A unit's number in a soft circle, or a tick once every item in it was done.
class _UnitNumber extends StatelessWidget {
  const _UnitNumber({required this.number, required this.done});

  final int number;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = done ? BrandColors.tintGreen : BrandColors.tintBlue;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: dark ? tint.withValues(alpha: 0.18) : tint, shape: BoxShape.circle),
      child: done
          ? Icon(
              Icons.check_rounded,
              size: 20,
              color: BrandColors.success(Theme.of(context).brightness),
              semanticLabel: 'مكتملة',
            )
          : Text(
              '$number',
              style: TextStyle(fontWeight: FontWeight.w700, color: dark ? tint : BrandColors.ink),
            ),
    );
  }
}

/// "متاح" or "مقفل" with an icon, so the state never relies on colour alone (§8.7). The track page
/// explains how to unlock it (or, without coupon redemption, only that it is unavailable).
class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = open ? BrandColors.success(b) : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(open ? Icons.lock_open : Icons.lock_outline, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          open ? 'متاح' : 'مقفل',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
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
      leading: Icon(Icons.article_outlined, color: Theme.of(context).colorScheme.primary),
      title: Text(lesson.titleAr),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => context.go('${Routes.subjects}/$subjectId/questions?lessonId=${lesson.id}'),
    );
  }
}

/// Arabic count agreement: درس واحد، درسان، 3–10 دروس، 11+ درساً.
String lessonCountLabel(int n) => switch (n) {
  0 => 'لا دروس بعد',
  1 => 'درس واحد',
  2 => 'درسان',
  >= 3 && <= 10 => '$n دروس',
  _ => '$n درساً',
};
