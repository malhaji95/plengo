import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/redesign_flags.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/network_avatar.dart';
import '../../shared/widgets/optional_asset.dart';
import '../access/access_banner.dart';
import '../flashcards/flashcard_providers.dart' show decksProvider;
import '../home/home_providers.dart';
import '../learning/scope_learning.dart';
import '../offline/download_widgets.dart';
import '../offline/offline_providers.dart';
import '../quizzes/quiz_providers.dart';
import 'catalog_providers.dart';
import 'learning_path.dart';
import 'locked_lessons.dart';
import 'scope_widgets.dart';

/// A subject page (V-Subject, v3 §3): the blue header with its art slot and progress, the access chip,
/// the four v3 shortcuts (تدريب · بطاقات بلينغو · راجع أخطاءك · بطاقاتي) with الاختبارات and بنك الأسئلة
/// under them, then every unit with the selected one drawn as a path of stations (flag `learningPath`;
/// off: the units accordion), general lessons and teacher tracks.
///
/// Locked content is shown on the stations themselves ([lockedLessonIds]): a locked station opens the
/// activation sheet. The old «هذا المحتوى يحتاج إلى تفعيل» box is gone; it only stays for a subject
/// without access that has no lessons to carry the lock, so activation is still reachable from it.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId));
    if (outline.hasValue) return _OutlineView(outline: outline.requireValue);
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth),
      body: AsyncView(
        value: outline,
        onRetry: () => ref.invalidate(subjectOutlineProvider(subjectId)),
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

class _OutlineView extends ConsumerStatefulWidget {
  const _OutlineView({required this.outline});

  final SubjectOutline outline;

  @override
  ConsumerState<_OutlineView> createState() => _OutlineViewState();
}

class _OutlineViewState extends ConsumerState<_OutlineView> {
  final _downloadKey = GlobalKey();

  void _showDownload() {
    final target = _downloadKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: PlengoMotion.of(context, PlengoMotion.sheet), alignment: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outline = widget.outline;
    final id = outline.subject.id;
    final progress = ref.watch(progressProvider((subjectId: id, teacherTrackId: null))).value;
    final empty =
        outline.units.isEmpty &&
        outline.lessons.isEmpty &&
        outline.tracks.isEmpty &&
        outline.questionCount.total == 0 &&
        outline.deckCount.total == 0 &&
        outline.quizCount.total == 0;
    final canDownload = ref.watch(offlinePacksAvailableProvider);
    final locked = _lockedLessons(ref, outline, progress);
    final hasLessons = outline.lessons.isNotEmpty || outline.units.any((u) => u.lessons.isNotEmpty);
    return ScopePage(
      header: ScopeHeader(
        title: outline.subject.nameAr,
        subtitle: outline.subject.description,
        subjectId: id,
        onDownload: canDownload ? _showDownload : null,
        art: SubjectHeaderArt(code: outline.subject.code),
      ),
      children: [
        if (outline.access.hasAccess || !hasLessons)
          ScopeAccessBanner(access: outline.access, subjectId: outline.subject.id),
        SubjectShortcuts(subjectId: id, questionCount: outline.questionCount, deckCount: outline.deckCount),
        if (outline.quizCount.total > 0 || outline.questionCount.total > 0) ...[
          const SizedBox(height: 8),
          ScopeShortcuts(
            subjectId: id,
            quizCount: outline.quizCount,
            questionCount: outline.questionCount,
            deckCount: outline.deckCount,
            quizzesPath: '${Routes.subjects}/$id/quizzes',
            decksPath: '${Routes.subjects}/$id/decks',
            questionsPath: '${Routes.subjects}/$id/questions',
            showRandom: false,
            showDecks: false,
          ),
        ],
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _downloadKey,
          child: OfflineDownloadTile(
            scope: (subjectId: id, teacherTrackId: null),
            label: 'تحميل الكل',
            doneLabel: 'المادة محمّلة',
          ),
        ),
        if (empty) const PlengoEmptyState(title: 'محتوى هذه المادة قيد الإعداد', icon: Icons.hourglass_empty),
        if (outline.units.isNotEmpty)
          RedesignFlags.learningPath
              ? _UnitsPath(outline: outline, progress: progress, locked: locked)
              : _UnitsAccordion(outline: outline, progress: progress, locked: locked),
        if (outline.lessons.isNotEmpty) ...[
          if (outline.units.isNotEmpty) const SectionHeader('دروس عامة', top: 12),
          for (final lesson in outline.lessons)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
              child: _LessonRow(
                lesson: lesson,
                subjectId: id,
                completion: progress?.lessons.where((l) => l.lessonId == lesson.id).firstOrNull?.completionPercent,
                locked: locked.contains(lesson.id),
              ),
            ),
        ],
        if (outline.tracks.isNotEmpty) ...[
          const SectionHeader('مسارات المدرسين', top: 12),
          for (final track in outline.tracks)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
              child: ListRow(
                leading: NetworkAvatar(url: track.teacherPhotoUrl, name: track.teacherNameAr, radius: 22),
                title: track.titleAr,
                caption: track.teacherNameAr,
                trailing: AccessChip(open: track.hasAccess),
                onTap: () => context.go('${Routes.tracks}/${track.id}'),
              ),
            ),
        ],
      ],
    );
  }
}

/// [lockedLessonIds] for the page: the subject's quizzes and decks are only fetched without access.
Set<String> _lockedLessons(WidgetRef ref, SubjectOutline outline, ScopeProgress? progress) {
  if (outline.access.hasAccess) return const {};
  final id = outline.subject.id;
  return lockedLessonIds(
        outline: outline,
        quizzes: ref.watch(quizzesProvider((subjectId: id, teacherTrackId: null, unitId: null, lessonId: null))),
        decks: ref.watch(decksProvider((subjectId: id, teacherTrackId: null, unitId: null, lessonId: null))),
        percents: {for (final l in progress?.lessons ?? const <LessonProgress>[]) l.lessonId: l.completionPercent},
      ) ??
      const {};
}

/// The subject's header art (v3 §3): `assets/subjects/<code>.png` (1080 × 480) when the owner's file
/// is bundled, else white science doodles over the blue.
class SubjectHeaderArt extends StatelessWidget {
  const SubjectHeaderArt({super.key, required this.code});

  final String code;

  static String assetFor(String code) => 'assets/subjects/$code.png';

  @override
  Widget build(BuildContext context) => OptionalAssetImage(
    path: assetFor(code),
    fit: BoxFit.cover,
    alignment: AlignmentDirectional.centerEnd,
    placeholder: const _Doodles(),
  );
}

/// Generic science doodles (flask, formula, bulb, microscope, bolt, globe) in faint white.
class _Doodles extends StatelessWidget {
  const _Doodles();

  @override
  Widget build(BuildContext context) {
    const c = Color(0x33FFFFFF);
    Widget doodle(IconData icon, double size, double angle) => Transform.rotate(
      angle: angle,
      child: Icon(icon, size: size, color: c),
    );
    return Stack(
      key: const Key('subject.art.placeholder'),
      clipBehavior: Clip.hardEdge,
      children: [
        PositionedDirectional(top: 14, start: 150, child: doodle(Icons.science_outlined, 34, -0.2)),
        PositionedDirectional(top: 62, start: 96, child: doodle(Icons.functions_rounded, 30, 0.1)),
        PositionedDirectional(bottom: 30, start: 20, child: doodle(Icons.lightbulb_outline_rounded, 30, 0.25)),
        PositionedDirectional(bottom: 24, start: 130, child: doodle(Icons.biotech_outlined, 32, -0.1)),
        PositionedDirectional(top: 20, end: 150, child: doodle(Icons.bolt_rounded, 28, 0.3)),
        PositionedDirectional(bottom: 34, end: 120, child: doodle(Icons.public_rounded, 26, 0)),
      ],
    );
  }
}

/// The four v3 shortcuts under the subject name (v3 §3): تدريب (تدرّب for this subject), بطاقات بلينغو
/// (the Plengo decks of this subject), راجع أخطاءك (the saved cards of this subject) and بطاقاتي (the
/// student's own groups for this subject).
class SubjectShortcuts extends StatelessWidget {
  const SubjectShortcuts({super.key, required this.subjectId, required this.questionCount, required this.deckCount});

  final String subjectId;
  final ContentCount questionCount;
  final ContentCount deckCount;

  @override
  Widget build(BuildContext context) {
    String q(Map<String, String> query) => Uri(queryParameters: query).query;
    return ShortcutRow(
      key: const Key('subject.shortcuts'),
      items: [
        ShortcutTile(
          icon: Icons.fact_check_rounded,
          hue: PlengoColors.blue,
          label: 'تدريب',
          count: questionCount.total > 0 ? '${questionCount.total}' : '',
          spoken: 'تدرّب على أسئلة المادة',
          onTap: () => context.go('${Routes.practice}/$subjectId'),
        ),
        ShortcutTile(
          icon: Icons.style_rounded,
          hue: PlengoColors.pink,
          label: 'بطاقات بلينغو',
          count: deckCount.total > 0 ? shortcutCount(deckCount) : '',
          spoken: 'فلاش كاردز بلينغو لهذه المادة',
          onTap: () => context.go('${Routes.plengoCards}?${q({'subjectId': subjectId})}'),
        ),
        ShortcutTile(
          icon: Icons.local_fire_department_rounded,
          hue: PlengoColors.orange,
          label: 'راجع أخطاءك',
          count: '',
          spoken: 'البطاقات المحفوظة والصعبة في هذه المادة',
          onTap: () => context.go('${Routes.saved}?${q({'filter': 'cards', 'subjectId': subjectId})}'),
        ),
        ShortcutTile(
          icon: Icons.collections_bookmark_rounded,
          hue: PlengoColors.green,
          label: 'بطاقاتي',
          count: '',
          spoken: 'مجموعات بطاقاتك لهذه المادة',
          onTap: () => context.go('${Routes.makeCardsGroups}?${q({'subjectId': subjectId})}'),
        ),
      ],
    );
  }
}

/// Per-lesson completion of the subject's general content.
Map<String, LessonProgress> _lessonProgress(ScopeProgress? p) => {
  for (final l in p?.lessons ?? const <LessonProgress>[]) l.lessonId: l,
};

int? _unitPercent(ScopeProgress? p, String unitId) =>
    p?.units.where((u) => u.unitId == unitId).firstOrNull?.completionPercent;

/// The node states of every lesson of the subject (units first, then general lessons).
Map<String, PathNodeState> _states(WidgetRef ref, SubjectOutline outline, ScopeProgress? progress) {
  // The resume list Home already loaded; never fetched from here.
  final resume = ref.exists(homeProvider) ? ref.watch(homeProvider).value?.resume : null;
  return pathNodeStates(
    lessons: [...outline.units.expand((u) => u.lessons), ...outline.lessons],
    percents: {for (final l in progress?.lessons ?? const <LessonProgress>[]) l.lessonId: l.completionPercent},
    resumeLessonId: resumeLessonId(outline.subject.id, resume),
  );
}

/// Learning-path layout (flag `learningPath`): every unit in order; the selected unit (the current one
/// by default) shows its banner and its stations, the others are compact rows (finished ones with a ✓)
/// that open their path when tapped. v3 §3: no collapsed «completed units» row.
class _UnitsPath extends ConsumerStatefulWidget {
  const _UnitsPath({required this.outline, required this.progress, required this.locked});

  final SubjectOutline outline;
  final ScopeProgress? progress;
  final Set<String> locked;

  @override
  ConsumerState<_UnitsPath> createState() => _UnitsPathState();
}

class _UnitsPathState extends ConsumerState<_UnitsPath> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final outline = widget.outline;
    final id = outline.subject.id;
    final states = _states(ref, outline, widget.progress);
    final lessonProgress = _lessonProgress(widget.progress);
    final quizzes = ref.watch(quizzesProvider((subjectId: id, teacherTrackId: null, unitId: null, lessonId: null)));
    StudentQuiz? unitQuiz(String unitId) =>
        quizzes.value?.where((q) => q.teacherTrackId == null && q.unitId == unitId && q.lessonId == null).firstOrNull;

    final complete = {
      for (final u in outline.units)
        if (unitComplete(u, states, _unitPercent(widget.progress, u.id))) u.id,
    };
    final currentUnit =
        outline.units.where((u) => u.lessons.any((l) => states[l.id] == PathNodeState.current)).firstOrNull ??
        outline.units.where((u) => !complete.contains(u.id)).firstOrNull ??
        outline.units.first;
    final selected = outline.units.where((u) => u.id == _selected).firstOrNull ?? currentUnit;

    Widget unitView(int index, UnitWithLessons unit) {
      final percentDone = _unitPercent(widget.progress, unit.id) ?? 0;
      if (unit.id != selected.id) {
        return _UnitRow(
          number: index + 1,
          unit: unit,
          done: complete.contains(unit.id),
          percentDone: percentDone,
          onTap: () => setState(() => _selected = unit.id),
        );
      }
      final quiz = unitQuiz(unit.id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UnitBanner(number: index + 1, unit: unit, percentDone: percentDone, hasQuiz: quiz != null),
          const SizedBox(height: 10),
          OfflineDownloadTile(
            scope: (subjectId: id, teacherTrackId: null),
            unitId: unit.id,
            label: 'تحميل الوحدة',
            doneLabel: 'الوحدة محمّلة',
          ),
          if (unit.lessons.isEmpty && quiz == null)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 16),
              child: Text(
                'لا توجد دروس في هذه الوحدة بعد',
                textAlign: TextAlign.center,
                style: PlengoType.sub.copyWith(color: context.surface.mute),
              ),
            )
          else
            LessonPath(
              key: ValueKey('path.${unit.id}'),
              subjectId: id,
              unitTitle: unit.titleAr,
              lessons: unit.lessons,
              states: states,
              progress: lessonProgress,
              quiz: quiz,
              locked: widget.locked,
              onLocked: (lesson) => showLockedLessonSheet(context, subjectId: id, lesson: lesson),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        for (final (i, u) in outline.units.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
            child: unitView(i, u),
          ),
      ],
    );
  }
}

/// The blue banner of the unit whose path is shown: «الوحدة N», its title, lessons and progress.
class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.number, required this.unit, required this.percentDone, required this.hasQuiz});

  final int number;
  final UnitWithLessons unit;
  final int percentDone;
  final bool hasQuiz;

  @override
  Widget build(BuildContext context) {
    final line = [
      hasQuiz ? '${lessonCountLabel(unit.lessons.length)} + اختبار الوحدة' : lessonCountLabel(unit.lessons.length),
      if (percentDone > 0) 'أنجزت ${percent(percentDone)}',
    ].join(' · ');
    return Semantics(
      container: true,
      header: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: PlengoColors.blue.base,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: PlengoColors.blue.shadow, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوحدة $number', style: PlengoType.chip.copyWith(color: const Color(0xE6FFFFFF))),
            Text(unit.titleAr, style: PlengoType.rowTitle.copyWith(color: Colors.white, fontSize: 17)),
            Text(line, style: PlengoType.caption.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A unit that is not shown as a path: its number (or ✓), title, lessons and progress.
class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.number,
    required this.unit,
    required this.done,
    required this.percentDone,
    required this.onTap,
  });

  final int number;
  final UnitWithLessons unit;
  final bool done;
  final int percentDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListRow(
    leading: _UnitBadge(number: number, done: done),
    title: unit.titleAr,
    caption: [
      lessonCountLabel(unit.lessons.length),
      if (done) 'مكتملة' else if (percentDone > 0) 'أنجزت ${percent(percentDone)}',
    ].join(' · '),
    onTap: onTap,
  );
}

/// A unit's number in a soft circle, or a tick once every item in it was done.
class _UnitBadge extends StatelessWidget {
  const _UnitBadge({required this.number, required this.done});

  final int number;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final hue = done ? PlengoColors.green : PlengoColors.blue;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: hue.soft, shape: BoxShape.circle),
      child: done
          ? Icon(Icons.check_rounded, size: 22, color: hue.ink, semanticLabel: 'مكتملة')
          : Text('$number', style: PlengoType.rowTitle.copyWith(color: hue.ink)),
    );
  }
}

/// Flag `learningPath` off: the restyled units accordion (number or ✓ badge, lessons count, %, bar,
/// unit download, lessons list with «التالي» on the current lesson).
class _UnitsAccordion extends ConsumerWidget {
  const _UnitsAccordion({required this.outline, required this.progress, required this.locked});

  final SubjectOutline outline;
  final ScopeProgress? progress;
  final Set<String> locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final id = outline.subject.id;
    final states = _states(ref, outline, progress);
    final lessonProgress = _lessonProgress(progress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('الوحدات', top: 12),
        for (final (i, unit) in outline.units.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
            child: PlengoCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey(unit.id),
                  initiallyExpanded: i == 0,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: s.mute,
                  collapsedIconColor: s.mute,
                  leading: _UnitBadge(number: i + 1, done: unitComplete(unit, states, _unitPercent(progress, unit.id))),
                  title: Text(unit.titleAr, style: PlengoType.rowTitle.copyWith(color: s.ink)),
                  subtitle: Text(
                    [
                      lessonCountLabel(unit.lessons.length),
                      if ((_unitPercent(progress, unit.id) ?? 0) > 0)
                        'أنجزت ${percent(_unitPercent(progress, unit.id)!)}',
                    ].join(' · '),
                    style: PlengoType.caption.copyWith(color: s.mute),
                  ),
                  childrenPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
                  children: [
                    if ((_unitPercent(progress, unit.id) ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 10),
                        child: PlengoProgressBar(
                          value: _unitPercent(progress, unit.id)! / 100,
                          label: percent(_unitPercent(progress, unit.id)!),
                        ),
                      ),
                    OfflineDownloadTile(
                      scope: (subjectId: id, teacherTrackId: null),
                      unitId: unit.id,
                      label: 'تحميل الوحدة',
                      doneLabel: 'الوحدة محمّلة',
                    ),
                    if (unit.lessons.isEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.all(12),
                        child: Text('لا توجد دروس في هذه الوحدة بعد', style: PlengoType.sub.copyWith(color: s.mute)),
                      ),
                    for (final (j, lesson) in unit.lessons.indexed)
                      _LessonRow(
                        lesson: lesson,
                        subjectId: id,
                        flat: true,
                        showDivider: j < unit.lessons.length - 1,
                        completion: lessonProgress[lesson.id]?.completionPercent,
                        next: states[lesson.id] == PathNodeState.current,
                        locked: locked.contains(lesson.id),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.subjectId,
    this.completion,
    this.flat = false,
    this.showDivider = true,
    this.next = false,
    this.locked = false,
  });

  final Lesson lesson;
  final String subjectId;
  final int? completion;
  final bool flat;
  final bool showDivider;
  final bool next;

  /// Locked content (v3 §3): a lock and «مقفل»; a tap opens the activation sheet.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final value = completion ?? 0;
    final done = value >= 100;
    if (locked) {
      return ListRow(
        flat: flat,
        showDivider: showDivider,
        icon: Icons.lock_rounded,
        hue: PlengoColors.red,
        title: lesson.titleAr,
        trailing: const LockedChip(),
        onTap: () => showLockedLessonSheet(context, subjectId: subjectId, lesson: lesson),
      );
    }
    return ListRow(
      flat: flat,
      showDivider: showDivider,
      icon: done ? Icons.check_rounded : Icons.article_rounded,
      hue: done ? PlengoColors.green : PlengoColors.yellow,
      title: lesson.titleAr,
      caption: done
          ? 'مكتمل'
          : value > 0
          ? 'أنجزت ${percent(value)}'
          : null,
      trailing: next ? const PlengoChip(label: 'التالي', icon: Icons.play_arrow_rounded) : null,
      onTap: () => context.go('${Routes.subjects}/$subjectId/lessons/${lesson.id}'),
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
