import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/optional_asset.dart';
import '../access/access_banner.dart';
import '../home/next_lesson_carousel.dart' show PageDots;
import '../questions/question_providers.dart';
import '../questions/question_view.dart' show InlineError, questionTypeLabel;
import '../quizzes/quiz_providers.dart';
import '../shell/app_drawer.dart';
import '../subjects/catalog_providers.dart';
import '../subjects/scope_widgets.dart' show ContentWidthBox, LockedChip;
import 'practice_providers.dart';

// تدرّب (v3 §5): [PracticeHomeScreen] at [Routes.practice], [PracticeSetupScreen] at
// `/practice/:subjectId` and [DiagramsScreen] at [Routes.practiceDiagrams] (a later phase).

/// تدرّب: a header, the subjects of the student's stage and «اختبارات بلينغو المخصصة».
class PracticeHomeScreen extends ConsumerWidget {
  const PracticeHomeScreen({super.key});

  static const headerAsset = 'assets/brand/practice_header.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(practiceSubjectsProvider);
    final menu = DrawerMenuButton.leadingOf(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: menu,
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: menu == null ? PlengoSpace.screen : null,
        title: const Text('تدرّب'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(practiceSubjectsProvider.future),
        child: ContentWidthBox(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 28),
            children: [
              const PracticeHeader(),
              const SectionHeader('اختر المادة'),
              AsyncView(
                value: subjects,
                onRetry: () => ref.invalidate(practiceSubjectsProvider),
                data: (items) => items.isEmpty
                    ? PlengoEmptyState(
                        title: 'لا توجد مواد لمرحلتك بعد',
                        message: 'اختر مرحلتك الدراسية لتظهر موادها هنا.',
                        icon: Icons.menu_book_outlined,
                        actionLabel: 'المواد',
                        onAction: () => context.go(Routes.subjects),
                      )
                    : _SubjectGrid(subjects: items),
              ),
              const SectionHeader('اختبارات بلينغو المخصصة'),
              ListRow(
                key: const Key('practice.diagrams'),
                icon: Icons.schema_rounded,
                hue: PlengoColors.green,
                title: 'رسمات العلوم',
                caption: 'سمِّ الأجزاء المرقّمة في الرسمة',
                onTap: () => context.go(Routes.practiceDiagrams),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page header: the owner's art (`assets/brand/practice_header.png`, 1080 × 420) when bundled,
/// else a drawn one: «تدريب», a line of copy and a clipboard with yellow sparkles.
class PracticeHeader extends ConsumerWidget {
  const PracticeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (assetBundled(ref, PracticeHomeScreen.headerAsset)) {
      return Semantics(
        header: true,
        label: 'تدريب',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PlengoRadius.hero),
          child: const AspectRatio(
            aspectRatio: 1080 / 420,
            child: OptionalAssetImage(
              path: PracticeHomeScreen.headerAsset,
              fit: BoxFit.cover,
              placeholder: SizedBox.shrink(),
            ),
          ),
        ),
      );
    }
    final blue = PlengoColors.blue;
    final yellow = PlengoColors.yellow.base;
    return Container(
      key: const Key('practice.header.drawn'),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 16, 18),
      decoration: BoxDecoration(color: blue.soft, borderRadius: BorderRadius.circular(PlengoRadius.hero)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('تدريب', style: PlengoType.title.copyWith(color: blue.ink)),
                ),
                const SizedBox(height: 2),
                Text(
                  'اختر المادة وابدأ التدريب على أسئلة الدروس',
                  style: PlengoType.sub.copyWith(color: PlengoColors.ink, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.assignment_turned_in_rounded, size: 40, color: blue.base),
                    ),
                  ),
                  PositionedDirectional(top: -6, end: -4, child: Icon(Icons.auto_awesome, size: 22, color: yellow)),
                  PositionedDirectional(
                    bottom: 2,
                    start: -8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: yellow, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subjects two to a row (three on wide screens), each in its subject colour; locked subjects keep
/// the «مقفل» chip but stay open: their free questions can be practised.
class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.subjects});

  final List<CatalogSubject> subjects;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 520 ? 3 : 2;
      return Column(
        children: [
          for (var r = 0; r < subjects.length; r += columns)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) const SizedBox(width: PlengoSpace.listGap),
                      Expanded(
                        child: r + c < subjects.length
                            ? _SubjectTile(subject: subjects[r + c])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});

  final CatalogSubject subject;

  @override
  Widget build(BuildContext context) {
    final hue = subjectHue(subject.id);
    final name = subject.nameAr.trim();
    return PlengoCard(
      key: Key('practice.subject.${subject.id}'),
      color: hue.soft,
      padding: const EdgeInsets.all(14),
      semanticsLabel: subject.hasAccess ? subject.nameAr : '${subject.nameAr}، مقفل',
      onTap: () => context.go('${Routes.practice}/${subject.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: hue.fill, borderRadius: BorderRadius.circular(PlengoRadius.iconTile)),
                child: Text(
                  name.isEmpty ? '؟' : name.characters.first,
                  style: PlengoType.section.copyWith(color: hue.onFill, height: 1.2),
                ),
              ),
              const Spacer(),
              if (!subject.hasAccess) const LockedChip(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subject.nameAr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Practice setup
// ---------------------------------------------------------------------------------------------

/// Practice setup for one subject (v3 §5): unit carousel → lessons → question categories → question
/// types → count → «ابدأ التدريب». Practice mode only; the old random practice (with exam mode) stays
/// one tap away.
class PracticeSetupScreen extends ConsumerWidget {
  const PracticeSetupScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId));
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth, title: const Text('تدريب')),
      body: AsyncView(
        value: outline,
        onRetry: () => ref.invalidate(subjectOutlineProvider(subjectId)),
        data: (o) => _SetupForm(key: ValueKey(o.subject.id), outline: o),
      ),
    );
  }
}

class _SetupForm extends ConsumerStatefulWidget {
  const _SetupForm({super.key, required this.outline});

  final SubjectOutline outline;

  @override
  ConsumerState<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends ConsumerState<_SetupForm> {
  /// Null: every unit.
  String? _unitId;
  late Set<String> _lessons = _scopeLessons.map((l) => l.id).toSet();
  final _categories = <String>{};
  final _types = <AttemptFiltersTypes>{};
  int _count = 20;
  bool _busy = false;
  String? _error;

  SubjectOutline get o => widget.outline;
  String get _subjectId => o.subject.id;

  /// The lessons the chosen unit offers (every unit: all of them, loose lessons last).
  List<Lesson> get _scopeLessons => [
    ...o.units.where((u) => _unitId == null || u.id == _unitId).expand((u) => u.lessons),
    if (_unitId == null) ...o.lessons,
  ];

  void _selectUnit(String? id) => setState(() {
    _unitId = id;
    _lessons = _scopeLessons.map((l) => l.id).toSet();
    _categories.clear();
    _error = null;
  });

  PracticeScope get _scope {
    final scope = _scopeLessons.map((l) => l.id).toList();
    final every = scope.every(_lessons.contains);
    return (
      subjectId: _subjectId,
      unitId: _unitId,
      lessonIds: every ? null : [for (final id in scope) if (_lessons.contains(id)) id].join(','),
    );
  }

  Future<void> _start(List<String> categoryIds) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await startAttempt(
        ref.read(learningRepositoryProvider),
        source: StartAttemptRequestSource.random,
        mode: StartAttemptRequestMode.practice,
        filters: practiceFilters(
          subjectId: _subjectId,
          unitId: _unitId,
          scopeLessonIds: _scopeLessons.map((l) => l.id).toList(),
          selectedLessonIds: _lessons,
          categoryIds: categoryIds,
          types: _types,
          count: _count,
        ),
      );
      if (mounted) unawaited(context.push('${Routes.attempts}/${a.attempt.id}'));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == 'VALIDATION_ERROR' ? 'لا توجد أسئلة متاحة تطابق هذه الاختيارات' : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (o.questionCount.total == 0) {
      return const PlengoEmptyState(title: 'لا توجد أسئلة في هذه المادة بعد', icon: Icons.quiz_outlined);
    }
    final lessons = _scopeLessons;
    final scope = _scope;
    final categories = lessons.isNotEmpty && _lessons.isEmpty ? null : ref.watch(practiceCategoriesProvider(scope));
    final list = categories?.value;
    final groups = groupCategories(list?.items ?? const []);
    final chosen = effectiveCategoryIds(groups, _categories);
    final match = list == null ? null : matchingCount(list, chosen);

    final String? reason = switch (match) {
      _ when lessons.isNotEmpty && _lessons.isEmpty => 'اختر درساً واحداً على الأقل',
      (accessible: 0, total: > 0) => 'أسئلة هذا الاختيار تحتاج إلى تفعيل',
      (accessible: 0, total: 0) => 'لا توجد أسئلة تطابق اختيارك',
      _ => null,
    };
    final locked = match != null && match.accessible == 0 && match.total > 0;

    Widget title(String text, {String? caption, Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(text, style: PlengoType.section.copyWith(color: s.ink, fontSize: 16)),
                ),
                if (caption != null) Text(caption, style: PlengoType.caption.copyWith(color: s.mute)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Column(
      children: [
        Expanded(
          child: ContentWidthBox(
            child: ListView(
              key: const Key('practice.setup'),
              padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 24),
              children: [
                Row(
                  children: [
                    SubjectIconTile.forSubject(_subjectId, icon: Icons.menu_book_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.subject.nameAr, style: PlengoType.section.copyWith(color: s.ink)),
                          Text('اختر تفاصيل التدريب', style: PlengoType.caption.copyWith(color: s.mute)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!o.access.hasAccess && !locked) ...[
                  const SizedBox(height: 10),
                  Text(
                    'تتدرّب على الأسئلة المجانية في هذه المادة.',
                    style: PlengoType.caption.copyWith(color: s.mute, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: PlengoSpace.section),
                if (o.units.isNotEmpty) ...[
                  title('اختر الوحدة'),
                  UnitCarousel(units: o.units, selected: _unitId, onSelected: _selectUnit),
                  const SizedBox(height: PlengoSpace.section),
                ],
                if (lessons.isNotEmpty) ...[
                  title(
                    'اختر الدروس',
                    caption: 'يمكنك اختيار أكثر من درس',
                    trailing: PlengoButton(
                      key: const Key('practice.lessons.all'),
                      label: _lessons.length == lessons.length ? 'إلغاء الكل' : 'تحديد الكل',
                      variant: PlengoButtonVariant.ghost,
                      size: PlengoButtonSize.small,
                      onPressed: () => setState(() {
                        _lessons = _lessons.length == lessons.length ? {} : lessons.map((l) => l.id).toSet();
                        _error = null;
                      }),
                    ),
                  ),
                  ..._lessonRows(lessons),
                  const SizedBox(height: PlengoSpace.section),
                ],
                if (categories != null) ..._categorySection(categories, groups, title),
                title('أنواع الأسئلة', caption: 'اتركها فارغة لكل الأنواع'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in AttemptFiltersTypes.values)
                      ToggleChip(
                        key: Key('practice.type.${t.name}'),
                        label: questionTypeLabel(t.name),
                        selected: _types.contains(t),
                        onTap: () => setState(() {
                          _types.contains(t) ? _types.remove(t) : _types.add(t);
                          _error = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: PlengoSpace.section),
                title('عدد الأسئلة'),
                PillSelector<int>(
                  padding: EdgeInsets.zero,
                  options: [
                    for (final n in practiceCounts)
                      PlengoOption(n, n == practiceAllQuestions ? 'جميع الأسئلة' : '$n'),
                  ],
                  selected: _count,
                  onSelected: (n) => setState(() => _count = n),
                ),
                if (locked) ...[
                  const SizedBox(height: PlengoSpace.section),
                  LockedNotice(subjectId: _subjectId),
                ],
                const SizedBox(height: 12),
                Center(
                  child: PlengoButton(
                    key: const Key('practice.random'),
                    label: 'تدريب عشوائي',
                    icon: Icons.shuffle_rounded,
                    variant: PlengoButtonVariant.ghost,
                    size: PlengoButtonSize.small,
                    onPressed: () => context.push(
                      Uri(path: Routes.randomPractice, queryParameters: {'subjectId': _subjectId}).toString(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _StartBar(
          available: match?.accessible,
          reason: reason,
          error: _error,
          busy: _busy,
          onStart: reason == null && !_busy ? () => _start(chosen) : null,
        ),
      ],
    );
  }

  List<Widget> _lessonRows(List<Lesson> lessons) {
    Widget row(Lesson l) => CheckRow(
      key: Key('practice.lesson.${l.id}'),
      title: l.titleAr,
      selected: _lessons.contains(l.id),
      onTap: () => setState(() {
        _lessons.contains(l.id) ? _lessons.remove(l.id) : _lessons.add(l.id);
        _error = null;
      }),
    );
    if (_unitId != null || o.units.length + (o.lessons.isEmpty ? 0 : 1) < 2) return [for (final l in lessons) row(l)];
    // Every unit: the lessons under their unit's name.
    final s = context.surface;
    Widget label(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(top: 6, bottom: 4),
      child: Text(text, style: PlengoType.chip.copyWith(color: s.mute)),
    );
    return [
      for (final u in o.units.where((u) => u.lessons.isNotEmpty)) ...[label(u.titleAr), for (final l in u.lessons) row(l)],
      if (o.lessons.isNotEmpty) ...[label('دروس عامة'), for (final l in o.lessons) row(l)],
    ];
  }

  List<Widget> _categorySection(
    AsyncValue<StudentQuestionCategoryList> categories,
    List<CategoryGroup> groups,
    Widget Function(String, {String? caption, Widget? trailing}) title,
  ) {
    final s = context.surface;
    final heading = title('تصنيف الأسئلة', caption: 'مثل: علّل، قارن، عرّف — اتركها فارغة لكل التصنيفات');
    if (categories.hasError && !categories.hasValue) {
      final offline = categories.error is ApiException && (categories.error as ApiException).code == 'NETWORK_ERROR';
      return [
        heading,
        Row(
          children: [
            Expanded(
              child: Text(
                offline ? 'تحتاج التصنيفات إلى اتصال بالإنترنت' : 'تعذّر تحميل التصنيفات',
                style: PlengoType.caption.copyWith(color: s.mute, fontWeight: FontWeight.w600),
              ),
            ),
            PlengoButton(
              label: 'إعادة المحاولة',
              variant: PlengoButtonVariant.ghost,
              size: PlengoButtonSize.small,
              onPressed: () => ref.invalidate(practiceCategoriesProvider(_scope)),
            ),
          ],
        ),
        const SizedBox(height: PlengoSpace.section),
      ];
    }
    if (!categories.hasValue) {
      return [
        heading,
        const SkeletonGroup(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Skeleton(width: 90, height: 44, radius: 99),
              Skeleton(width: 70, height: 44, radius: 99),
              Skeleton(width: 110, height: 44, radius: 99),
            ],
          ),
        ),
        const SizedBox(height: PlengoSpace.section),
      ];
    }
    if (groups.isEmpty) return const [];
    String countOf(int accessible, int total) => accessible == total ? '$total' : '$accessible/$total';
    ToggleChip chip(StudentQuestionCategory c, int accessible, int total, {bool covered = false}) => ToggleChip(
      key: Key('practice.category.${c.id}'),
      label: c.nameAr,
      count: countOf(accessible, total),
      locked: accessible == 0,
      selected: covered || _categories.contains(c.id),
      onTap: covered
          ? null
          : () => setState(() {
              _categories.contains(c.id) ? _categories.remove(c.id) : _categories.add(c.id);
              _error = null;
            }),
    );
    final single = groups.where((g) => g.children.isEmpty).toList();
    final nested = groups.where((g) => g.children.isNotEmpty).toList();
    return [
      heading,
      if (single.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final g in single) chip(g.category, g.accessibleCount, g.questionCount)],
        ),
      for (final g in nested)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: BorderRadius.circular(PlengoRadius.option),
            border: Border.all(color: s.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              chip(g.category, g.accessibleCount, g.questionCount),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in g.children)
                      chip(c, c.accessibleCount, c.questionCount, covered: _categories.contains(g.id)),
                  ],
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: PlengoSpace.section),
    ];
  }
}

/// The sticky bottom of the setup: how many questions are open for the selection, why starting is
/// not possible (when it is not), and «ابدأ التدريب».
class _StartBar extends StatelessWidget {
  const _StartBar({
    required this.available,
    required this.reason,
    required this.error,
    required this.busy,
    required this.onStart,
  });

  final int? available;
  final String? reason;
  final String? error;
  final bool busy;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final note = reason ?? (available == null ? null : 'متاح لهذا الاختيار: ${questionCountLabel(available!)}');
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
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[InlineError(error), const SizedBox(height: 8)],
                  if (note != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        note,
                        key: const Key('practice.start.note'),
                        textAlign: TextAlign.center,
                        style: PlengoType.caption.copyWith(
                          color: reason != null ? (s.isDark ? PlengoColors.red.base : PlengoColors.red.ink) : s.mute,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  PlengoButton(
                    key: const Key('practice.start'),
                    label: 'ابدأ التدريب',
                    icon: Icons.play_arrow_rounded,
                    busy: busy,
                    onPressed: onStart,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The units of a subject as a horizontal carousel of cards (first «كل الوحدات»), with page dots.
class UnitCarousel extends StatefulWidget {
  const UnitCarousel({super.key, required this.units, required this.selected, required this.onSelected});

  final List<UnitWithLessons> units;

  /// Null: «كل الوحدات».
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  State<UnitCarousel> createState() => _UnitCarouselState();
}

class _UnitCarouselState extends State<UnitCarousel> {
  PageController? _controller;
  double _fraction = 0;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double width) {
    final fraction = (150 / width).clamp(0.25, 0.9);
    if (_controller == null || (fraction - _fraction).abs() > 0.01) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(viewportFraction: fraction, initialPage: _page);
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    final entries = <UnitWithLessons?>[null, ...widget.units];
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return LayoutBuilder(
      builder: (context, box) {
        final controller = _controllerFor(box.maxWidth);
        final visible = (1 / _fraction).floor().clamp(1, entries.length);
        final pages = entries.length - visible + 1;
        return Column(
          children: [
            SizedBox(
              height: 92 + 62 * scale,
              child: PageView.builder(
                key: const Key('practice.units'),
                controller: controller,
                padEnds: false,
                itemCount: entries.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final u = entries[i];
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10, bottom: 6),
                    child: _UnitCard(
                      index: i,
                      title: u?.titleAr ?? 'كل الوحدات',
                      caption: u == null
                          ? '${widget.units.length} ${widget.units.length <= 10 && widget.units.length > 2 ? 'وحدات' : 'وحدة'}'
                          : '${u.lessons.length} ${u.lessons.length <= 10 && u.lessons.length > 2 ? 'دروس' : 'درس'}',
                      selected: u?.id == widget.selected,
                      onTap: () => widget.onSelected(u?.id),
                    ),
                  );
                },
              ),
            ),
            if (pages > 1) ...[
              const SizedBox(height: 6),
              PageDots(
                count: pages,
                index: _page.clamp(0, pages - 1),
                label: 'الوحدات ${_page.clamp(0, pages - 1) + 1} من $pages',
                active: PlengoColors.blue.base,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.index,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = index == 0 ? PlengoColors.blue : PlengoColors.all[(index - 1) % PlengoColors.all.length];
    final green = PlengoColors.green;
    final r = BorderRadius.circular(PlengoRadius.option);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title، $caption',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? green.soft : s.card,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(color: selected ? green.base : s.line, width: 2),
        ),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SubjectIconTile(
                      icon: index == 0 ? Icons.layers_rounded : Icons.auto_stories_rounded,
                      hue: hue,
                      size: 40,
                    ),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle_rounded, color: green.ink, size: 22),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PlengoType.rowTitle.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: selected ? PlengoColors.ink : s.ink,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PlengoType.caption.copyWith(color: selected ? green.ink : s.mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lesson with a checkbox (green-soft when chosen, v3 mockup).
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final green = PlengoColors.green;
    final r = BorderRadius.circular(PlengoRadius.row);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        checked: selected,
        label: title,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: selected ? green.soft : s.card,
          shape: RoundedRectangleBorder(
            borderRadius: r,
            side: BorderSide(color: selected ? green.base : s.line, width: 1.5),
          ),
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: PlengoType.rowTitle.copyWith(
                          color: selected ? PlengoColors.ink : s.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selected ? green.base : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: selected ? green.base : s.mute, width: 2),
                      ),
                      child: selected ? const Icon(Icons.check_rounded, size: 18, color: PlengoColors.ink) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A multi-select pill: ink fill + ✓ when on (dark mode: yellow), never colour alone. [count] shows
/// after the label; [locked] adds a lock (nothing open to practise); a null [onTap] is shown selected
/// but fixed (a child covered by its selected parent).
class ToggleChip extends StatelessWidget {
  const ToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? count;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final fixed = onTap == null;
    final bg = selected
        ? (fixed ? s.track : (s.isDark ? PlengoColors.yellow.base : PlengoColors.ink))
        : s.card;
    final fg = selected && !fixed ? (s.isDark ? PlengoColors.ink : Colors.white) : s.ink;
    final r = BorderRadius.circular(PlengoRadius.pill);
    final spoken = [label, ?count == null ? null : '$count سؤال', if (locked) 'مقفل'].join('، ');
    return Semantics(
      button: true,
      toggled: selected,
      enabled: !fixed,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(color: selected && !fixed ? bg : s.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[Icon(Icons.check_rounded, size: 18, color: fg), const SizedBox(width: 6)],
                  if (locked && !selected) ...[
                    Icon(Icons.lock_rounded, size: 16, color: s.mute),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      count!,
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected && !fixed ? fg : s.mute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// رسمات العلوم: name the numbered parts of a diagram (v3 §9, a later phase).
class DiagramsScreen extends StatelessWidget {
  const DiagramsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoonScaffold(title: 'رسمات العلوم', icon: Icons.schema_rounded, hue: PlengoColors.green);
}
