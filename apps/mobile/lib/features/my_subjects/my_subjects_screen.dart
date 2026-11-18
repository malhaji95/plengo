import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../access/access_format.dart';
import '../home/home_providers.dart';
import '../learning/scope_learning.dart';
import '../shell/app_drawer.dart';
import '../subjects/catalog_providers.dart';
import '../subjects/learning_path.dart' show resumeLessonId;
import 'my_subjects_providers.dart';

/// موادي (v3 §4): every subject or track the student has access to (Home's `myAccess`), how far they
/// got (completion %, the current lesson) and four ways in: «متابعة», «مراجعة البطاقات الصعبة» (saved
/// cards of the subject), «بطاقاتي» (the subject's lessons path with progress) and «إحصائياتي». The
/// due-card review sits on top (Home's «مراجعة البطاقات المستحقة» opens this page). Nothing purchased:
/// an empty state pointing to المواد and the free content.
class MySubjectsScreen extends ConsumerWidget {
  const MySubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final menu = DrawerMenuButton.leadingOf(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: menu,
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: menu == null ? PlengoSpace.screen : null,
        title: const Text('موادي'),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: home,
          onRetry: () => ref.invalidate(homeProvider),
          data: (h) => RefreshIndicator(
            onRefresh: () => ref.refresh(homeProvider.future),
            child: _Body(home: h),
          ),
        ),
      ),
    );
  }
}

/// One entry per scope: several entitlements to the same subject or track show once.
List<AccessScope> myScopes(List<MyEntitlement> access) {
  final seen = <String>{};
  return [
    for (final e in access)
      if (seen.add('${e.scope.subjectId}:${e.scope.teacherTrackId ?? ''}')) e.scope,
  ];
}

class _Body extends StatelessWidget {
  const _Body({required this.home});

  final Home home;

  @override
  Widget build(BuildContext context) {
    final scopes = myScopes(home.myAccess);
    final due = home.today.dueCards;
    const padding = EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 28);
    if (scopes.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          PlengoEmptyState(
            title: 'لم تفعّل أي مادة بعد',
            message: 'فعّل مادة لتتابع تقدّمك فيها هنا، أو ابدأ بالمحتوى المجاني',
            icon: Icons.school_outlined,
            hue: PlengoColors.blue,
            actionLabel: 'تصفّح المواد',
            onAction: () => context.go(Routes.subjects),
          ),
          if (home.freeSubjects.isNotEmpty) ...[
            const SectionHeader('محتوى مجاني', top: 0),
            for (final f in home.freeSubjects)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                child: ListRow(
                  icon: Icons.lock_open_rounded,
                  hue: subjectHue(f.subjectId),
                  title: f.nameAr,
                  caption: '${f.freeCount} عنصراً مجانياً',
                  onTap: () => context.go('${Routes.subjects}/${f.subjectId}'),
                ),
              ),
          ],
        ],
      );
    }
    return ListView(
      padding: padding,
      children: [
        if (due > 0) ...[
          PlengoButton(
            key: const Key('mySubjects.due'),
            label: 'مراجعة البطاقات المستحقة ($due)',
            icon: Icons.style_outlined,
            onPressed: () => context.push(Routes.dueStudy),
          ),
          const SizedBox(height: PlengoSpace.section),
        ],
        for (final s in scopes)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.section),
            child: MySubjectCard(scope: s, resume: home.resume),
          ),
      ],
    );
  }
}

/// A subject (or track) of موادي: icon, name, completion ring, the current lesson and its actions.
class MySubjectCard extends ConsumerWidget {
  const MySubjectCard({super.key, required this.scope, this.resume = const []});

  final AccessScope scope;
  final List<ResumeItem> resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final track = scope.scopeType == AccessScopeScopeType.teacherTrack;
    final id = scope.subjectId;
    final hue = subjectHue(track ? (scope.teacherTrackId ?? id) : id);
    final progress = ref
        .watch(progressProvider((subjectId: id, teacherTrackId: track ? scope.teacherTrackId : null)))
        .value;
    // The current lesson: the one Home last resumed in this subject, else the next one below 100 %.
    final outline = track ? null : ref.watch(subjectOutlineProvider(id)).value;
    final lessons = outline == null ? const <Lesson>[] : orderedLessons(outline);
    final resumed = resumeLessonId(id, resume);
    final lesson =
        lessons.where((l) => l.id == resumed).firstOrNull ?? (outline == null ? null : nextLesson(outline, progress));
    final pct = progress?.completionPercent;
    final title = scopeTitle(scope);
    final subjectPath = track ? '${Routes.tracks}/${scope.teacherTrackId}' : '${Routes.subjects}/$id';
    final caption = lesson != null
        ? 'الدرس الحالي: ${lesson.titleAr}'
        : lessons.isNotEmpty
        ? 'أنهيت كل الدروس'
        : scopeSubtitle(scope);
    return PlengoCard(
      key: Key('mySubject.${scope.teacherTrackId ?? id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                SubjectIconTile(icon: track ? Icons.route_rounded : Icons.menu_book_rounded, hue: hue, soft: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: PlengoType.rowTitle.copyWith(fontSize: 17, color: s.ink)),
                      ),
                      Text(caption, style: PlengoType.caption.copyWith(color: s.mute)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProgressRing(
                  value: (pct ?? 0) / 100,
                  label: pct == null ? '–' : percent(pct),
                  size: 56,
                  strokeWidth: 6,
                  color: hue.ink,
                  semanticsLabel: pct == null ? 'التقدّم' : 'مكتمل ${percent(pct)}',
                  labelStyle: TextStyle(
                    fontFamily: PlengoType.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: s.ink,
                  ),
                ),
              ],
            ),
          ),
          if (pct != null) ...[
            const SizedBox(height: 12),
            PlengoProgressBar(value: pct / 100, color: hue.base, label: '${percent(pct)} مكتمل'),
          ],
          const SizedBox(height: 14),
          PlengoButton(
            key: Key('mySubject.continue.$id'),
            label: 'متابعة',
            icon: Icons.play_arrow_rounded,
            semanticsLabel: 'متابعة: $title',
            onPressed: () =>
                context.go(lesson != null && !track ? '${Routes.subjects}/$id/lessons/${lesson.id}' : subjectPath),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PlengoButton(
                label: 'مراجعة البطاقات الصعبة',
                icon: Icons.local_fire_department_outlined,
                variant: PlengoButtonVariant.secondary,
                size: PlengoButtonSize.small,
                onPressed: () => context.go(
                  Uri(path: Routes.saved, queryParameters: {'filter': 'cards', 'subjectId': id}).toString(),
                ),
              ),
              PlengoButton(
                label: 'بطاقاتي',
                icon: Icons.route_rounded,
                variant: PlengoButtonVariant.secondary,
                size: PlengoButtonSize.small,
                onPressed: () => context.go(subjectPath),
              ),
              PlengoButton(
                label: 'إحصائياتي',
                icon: Icons.bar_chart_rounded,
                variant: PlengoButtonVariant.secondary,
                size: PlengoButtonSize.small,
                onPressed: () => context.go('${Routes.stats}/subjects/$id'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
