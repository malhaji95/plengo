import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../access/access_providers.dart';
import '../questions/question_view.dart' show InlineError;
import '../subjects/catalog_providers.dart';
import 'diagram_repository.dart';
import 'diagram_results.dart';
import 'diagram_session.dart';
import 'diagram_widgets.dart';

/// What the practice covers: a whole unit, several lessons or one lesson.
enum DiagramMode { unit, lessons, lesson }

/// The most diagrams one practice can draw (contracts DIAGRAM_PRACTICE_MAX).
const diagramPracticeMax = 50;

/// «دروس عامة»: the subject's lessons outside any unit, in the unit picker of the lesson modes.
const _generalLessons = '';

enum _Stage { setup, session, results }

/// رسمات العلوم (V3_PLAN §9): choose the subject, «وحدة كاملة» / «عدة دروس» / «درس واحد», the unit or
/// lessons, how many diagrams and when to check; then name the numbered parts of each diagram; then
/// the results with «إعادة التدريب» / «تدريب آخر». Online only.
class DiagramsScreen extends ConsumerStatefulWidget {
  const DiagramsScreen({super.key, this.subjectId, this.teacherTrackId});

  /// Preselected subject (`?subjectId=`); else the first subject of the student's level.
  final String? subjectId;
  final String? teacherTrackId;

  @override
  ConsumerState<DiagramsScreen> createState() => _DiagramsScreenState();
}

class _DiagramsScreenState extends ConsumerState<DiagramsScreen> {
  _Stage _stage = _Stage.setup;
  String? _subjectId;
  DiagramMode _mode = DiagramMode.unit;
  String? _unitId;
  final _lessons = <String>{};
  String? _lessonId;
  int _count = 5;
  bool _checkEach = true;
  bool _busy = false;
  String? _error;

  List<PracticeDiagram> _diagrams = const [];
  List<DiagramCheckResult> _results = const [];
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjectId;
  }

  void _pickSubject(String id) => setState(() {
    _subjectId = id;
    _unitId = null;
    _lessons.clear();
    _lessonId = null;
    _error = null;
  });

  /// The unit the pickers show: the chosen one, else the first unit (or the general lessons).
  String? _unitOf(SubjectOutline o) {
    final chosen = _unitId;
    if (chosen == _generalLessons && _mode != DiagramMode.unit && o.lessons.isNotEmpty) return chosen;
    if (chosen != null && o.units.any((u) => u.id == chosen)) return chosen;
    if (o.units.isNotEmpty) return o.units.first.id;
    return _mode == DiagramMode.unit || o.lessons.isEmpty ? null : _generalLessons;
  }

  List<Lesson> _pool(SubjectOutline o) {
    final unit = _unitOf(o);
    if (unit == _generalLessons) return o.lessons;
    return o.units.where((u) => u.id == unit).expand((u) => u.lessons).toList();
  }

  /// The scope of the current choice, or null while it is incomplete (no lesson picked).
  DiagramScope? _scope(String subjectId, SubjectOutline o) {
    DiagramScope scope({String? unitId, String? lessonIds}) =>
        (subjectId: subjectId, teacherTrackId: widget.teacherTrackId, unitId: unitId, lessonIds: lessonIds);
    switch (_mode) {
      case DiagramMode.unit:
        // A subject without units practises all its diagrams.
        return scope(unitId: _unitOf(o));
      case DiagramMode.lessons:
        final ids = [
          for (final l in _pool(o))
            if (_lessons.contains(l.id)) l.id,
        ];
        return ids.isEmpty ? null : scope(lessonIds: ids.join(','));
      case DiagramMode.lesson:
        final id = _pool(o).where((l) => l.id == _lessonId).firstOrNull?.id;
        return id == null ? null : scope(lessonIds: id);
    }
  }

  Future<void> _start(DiagramScope scope, int count) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await ref.read(diagramRepositoryProvider).start(diagramPracticeRequest(scope, count));
      if (!mounted) return;
      if (p.diagrams.isEmpty) {
        setState(() => _error = 'لا توجد رسومات متاحة في هذا الاختيار');
        return;
      }
      setState(() {
        _diagrams = p.diagrams;
        _run++;
        _stage = _Stage.session;
      });
    } catch (e) {
      if (mounted) setState(() => _error = diagramErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.practice);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.session:
        return DiagramSession(
          key: ValueKey('session.$_run'),
          diagrams: _diagrams,
          checkEach: _checkEach,
          onExit: () => setState(() => _stage = _Stage.setup),
          onDone: (results) => setState(() {
            _results = results;
            _stage = _Stage.results;
          }),
        );
      case _Stage.results:
        return Scaffold(
          appBar: AppBar(
            leading: PlengoBackButton(onPressed: () => setState(() => _stage = _Stage.setup)),
            leadingWidth: kPlengoLeadingWidth,
            title: const Text('رسمات العلوم'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DiagramResults(
                diagrams: _diagrams,
                results: _results,
                onRetry: () => setState(() {
                  _run++;
                  _stage = _Stage.session;
                }),
                onAnother: () => setState(() => _stage = _Stage.setup),
              ),
            ),
          ),
        );
      case _Stage.setup:
        return Scaffold(
          appBar: AppBar(
            leading: PlengoBackButton(onPressed: _leave),
            leadingWidth: kPlengoLeadingWidth,
            title: const Text('رسمات العلوم'),
          ),
          body: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: _setup(context)),
          ),
        );
    }
  }

  Widget _setup(BuildContext context) {
    final me = ref.watch(authControllerProvider).value;
    final level = me?.educationLevelId;
    final subjects = level == null
        ? null
        : ref.watch(
            subjectsProvider((
              levelId: level,
              universityId: me!.universityId,
              facultyId: me.facultyId,
              academicYearId: me.academicYearId,
            )),
          );
    final list = subjects?.value ?? const <CatalogSubject>[];
    final subjectId = _subjectId ?? list.firstOrNull?.id;
    final s = context.surface;

    final children = <Widget>[
      const DiagramSteps(current: 0),
      const SizedBox(height: 16),
      if (list.length > 1 || (list.isNotEmpty && subjectId != null && !list.any((x) => x.id == subjectId))) ...[
        Text('المادة', style: PlengoType.rowTitle.copyWith(color: s.ink)),
        const SizedBox(height: 8),
        PillSelector<String>(
          key: const Key('diagrams.subjects'),
          padding: EdgeInsets.zero,
          options: [for (final x in list) PlengoOption(x.id, x.nameAr)],
          selected: subjectId,
          onSelected: _pickSubject,
        ),
        const SizedBox(height: 16),
      ],
    ];

    if (subjectId == null) {
      final loading = subjects?.isLoading ?? false;
      final error = subjects?.error;
      return ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
        children: [
          ...children,
          if (loading)
            const PlengoLoadingSkeleton(hero: false, padding: EdgeInsets.zero)
          else if (error != null)
            _ErrorBox(error: error, onRetry: () => ref.invalidate(subjectsProvider))
          else
            const PlengoEmptyState(
              icon: Icons.schema_rounded,
              hue: PlengoColors.green,
              title: 'لا توجد مواد لرسمات العلوم',
              message: 'اختر مرحلتك الدراسية من حسابي لتظهر موادك هنا.',
            ),
        ],
      );
    }

    final outline = ref.watch(subjectOutlineProvider(subjectId));
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
      children: [
        ...children,
        switch (outline) {
          AsyncValue(:final value?) => _choices(context, subjectId, value),
          AsyncValue(:final error?) => _ErrorBox(
            error: error,
            onRetry: () => ref.invalidate(subjectOutlineProvider(subjectId)),
          ),
          _ => const PlengoLoadingSkeleton(hero: false, padding: EdgeInsets.zero),
        },
      ],
    );
  }

  Widget _choices(BuildContext context, String subjectId, SubjectOutline o) {
    final s = context.surface;
    final scope = _scope(subjectId, o);
    final available = scope == null ? null : ref.watch(diagramListProvider(scope));
    final unit = _unitOf(o);
    final pool = _pool(o);
    final accessible = available?.value?.accessibleCount;
    final locked = available?.value?.lockedCount ?? 0;
    final max = accessible == null ? 0 : accessible.clamp(0, diagramPracticeMax);
    final count = max == 0 ? 0 : _count.clamp(1, max);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: PlengoType.rowTitle.copyWith(color: s.ink)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          o.subject.nameAr,
          key: const Key('diagrams.subjectName'),
          style: PlengoType.section.copyWith(color: s.ink),
        ),
        const SizedBox(height: 12),
        PlengoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label('اختر ما تريد التدريب عليه'),
              SegmentedControl<DiagramMode>(
                key: const Key('diagrams.mode'),
                segments: const [
                  PlengoOption(DiagramMode.unit, 'وحدة كاملة', icon: Icons.menu_book_outlined),
                  PlengoOption(DiagramMode.lessons, 'عدة دروس', icon: Icons.layers_outlined),
                  PlengoOption(DiagramMode.lesson, 'درس واحد', icon: Icons.description_outlined),
                ],
                selected: _mode,
                onChanged: (m) => setState(() {
                  _mode = m;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              if (o.units.isNotEmpty || (_mode != DiagramMode.unit && o.lessons.isNotEmpty)) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('diagrams.unit.$_mode'),
                  initialValue: unit,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الوحدة'),
                  items: [
                    for (final u in o.units)
                      DropdownMenuItem(
                        value: u.id,
                        child: Text(u.titleAr, overflow: TextOverflow.ellipsis),
                      ),
                    if (_mode != DiagramMode.unit && o.lessons.isNotEmpty)
                      const DropdownMenuItem(value: _generalLessons, child: Text('دروس عامة')),
                  ],
                  onChanged: (v) => setState(() {
                    _unitId = v;
                    _lessons.clear();
                    _lessonId = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
              ],
              if (_mode == DiagramMode.lessons) ...[
                label('الدروس'),
                if (pool.isEmpty)
                  Text('لا توجد دروس في هذه الوحدة', style: PlengoType.sub.copyWith(color: s.mute))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in pool)
                        _LessonToggle(
                          key: Key('diagrams.lesson.${l.id}'),
                          label: l.titleAr,
                          selected: _lessons.contains(l.id),
                          onTap: () => setState(() {
                            _lessons.contains(l.id) ? _lessons.remove(l.id) : _lessons.add(l.id);
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
              if (_mode == DiagramMode.lesson) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('diagrams.lesson.$unit'),
                  initialValue: pool.any((l) => l.id == _lessonId) ? _lessonId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الدرس'),
                  hint: const Text('اختر الدرس'),
                  items: [
                    for (final l in pool)
                      DropdownMenuItem(
                        value: l.id,
                        child: Text(l.titleAr, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _lessonId = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
              ],
              _Availability(
                scope: scope,
                value: available,
                hint: _mode == DiagramMode.lessons ? 'اختر درساً واحداً على الأقل' : 'اختر درساً لترى رسوماته',
                onRetry: scope == null ? null : () => ref.invalidate(diagramListProvider(scope)),
              ),
              if (accessible != null && accessible > 0) ...[
                const SizedBox(height: 16),
                label('عدد الرسومات'),
                _Stepper(value: count, min: 1, max: max, onChanged: (v) => setState(() => _count = v)),
                const SizedBox(height: 16),
                label('طريقة التصحيح'),
                RadioRow(
                  key: const Key('diagrams.check.each'),
                  title: 'تصحيح بعد كل رسمة',
                  selected: _checkEach,
                  onTap: () => setState(() => _checkEach = true),
                ),
                const SizedBox(height: 8),
                RadioRow(
                  key: const Key('diagrams.check.end'),
                  title: 'تصحيح في النهاية',
                  selected: !_checkEach,
                  onTap: () => setState(() => _checkEach = false),
                ),
              ],
            ],
          ),
        ),
        if (accessible == 0) ...[
          const SizedBox(height: 16),
          if (locked > 0) _LockedBox(locked: locked) else const _EmptyBox(),
        ],
        const SizedBox(height: 16),
        if (_error != null) ...[InlineError(_error), const SizedBox(height: 12)],
        PlengoButton(
          key: const Key('diagrams.start'),
          label: 'ابدأ',
          icon: Icons.play_arrow_rounded,
          busy: _busy,
          onPressed: scope == null || count == 0 || _busy ? null : () => _start(scope, count),
        ),
      ],
    );
  }
}

/// «N رسمة متاحة» and «M مقفلة» for the current choice (or what is missing, loading, offline).
class _Availability extends StatelessWidget {
  const _Availability({required this.scope, required this.value, required this.hint, required this.onRetry});

  final DiagramScope? scope;
  final AsyncValue<StudentDiagramList>? value;
  final String hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final v = value;
    if (scope == null || v == null) {
      return Text(
        hint,
        key: const Key('diagrams.hint'),
        style: PlengoType.sub.copyWith(color: s.mute),
      );
    }
    return switch (v) {
      AsyncValue(:final value?) => Wrap(
        key: const Key('diagrams.available'),
        spacing: 8,
        runSpacing: 8,
        children: [
          PlengoChip(
            label: '${value.accessibleCount} رسمة متاحة',
            hue: value.accessibleCount > 0 ? PlengoColors.green : PlengoColors.orange,
            icon: Icons.schema_outlined,
          ),
          if (value.lockedCount > 0)
            PlengoChip(label: '${value.lockedCount} مقفلة', hue: PlengoColors.red, icon: Icons.lock_rounded),
        ],
      ),
      AsyncValue(:final error?) => _ErrorBox(error: error, onRetry: onRetry, compact: true),
      _ => const Align(alignment: AlignmentDirectional.centerStart, child: Skeleton(width: 140, height: 28)),
    };
  }
}

/// − value + (1 … max).
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: BorderRadius.circular(PlengoRadius.input),
        border: Border.all(color: s.line, width: 1.5),
      ),
      child: Row(
        children: [
          PlengoIconButton(
            key: const Key('diagrams.count.minus'),
            icon: Icons.remove_rounded,
            tooltip: 'أقل',
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label: '$value رسومات من $max',
              excludeSemantics: true,
              child: Text(
                '$value',
                key: const Key('diagrams.count'),
                textAlign: TextAlign.center,
                style: PlengoType.section.copyWith(color: s.ink),
              ),
            ),
          ),
          PlengoIconButton(
            key: const Key('diagrams.count.plus'),
            icon: Icons.add_rounded,
            tooltip: 'أكثر',
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _LockedBox extends ConsumerWidget {
  const _LockedBox({required this.locked});

  final int locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final red = PlengoColors.red;
    final redeem = ref.watch(couponRedemptionProvider);
    return Container(
      key: const Key('diagrams.locked'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: red.soft, borderRadius: BorderRadius.circular(PlengoRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, color: red.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text('رسومات هذا الاختيار مقفلة ($locked)', style: PlengoType.rowTitle.copyWith(color: red.ink)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('فعّل المادة لتتدرّب على رسوماتها.', style: PlengoType.sub.copyWith(color: red.ink)),
          if (redeem) ...[
            const SizedBox(height: 10),
            PlengoButton(
              label: 'إدخال كود التفعيل',
              icon: Icons.vpn_key_outlined,
              size: PlengoButtonSize.small,
              expand: true,
              onPressed: () => context.push(Routes.redeem),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) => const PlengoEmptyState(
    key: Key('diagrams.empty'),
    icon: Icons.schema_outlined,
    hue: PlengoColors.green,
    title: 'لا توجد رسومات هنا بعد',
    message: 'جرّب وحدة أو دروساً أخرى.',
  );
}

/// Offline («تحتاج إلى اتصال بالإنترنت») or another error, with «إعادة المحاولة».
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error, required this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final offline = isOfflineError(error);
    if (!compact) {
      return PlengoErrorState(
        key: const Key('diagrams.error'),
        icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        hue: offline ? PlengoColors.orange : PlengoColors.red,
        title: diagramErrorText(error),
        message: offline ? 'رسمات العلوم تحتاج إلى الإنترنت لتحميل الصور وتصحيح الإجابات.' : null,
        onRetry: onRetry,
      );
    }
    final hue = offline ? PlengoColors.orange : PlengoColors.red;
    return Container(
      key: const Key('diagrams.error'),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
      decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(PlengoRadius.input)),
      child: Row(
        children: [
          Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded, size: 20, color: hue.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              diagramErrorText(error),
              style: PlengoType.sub.copyWith(color: hue.ink, fontWeight: FontWeight.w700),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text('إعادة المحاولة', style: TextStyle(color: hue.ink)),
            ),
        ],
      ),
    );
  }
}

/// A multi-select pill: ink fill + ✓ when on (dark mode: yellow), never colour alone.
class _LessonToggle extends StatelessWidget {
  const _LessonToggle({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final bg = selected ? (s.isDark ? PlengoColors.yellow.base : PlengoColors.ink) : s.card;
    final fg = selected ? (s.isDark ? PlengoColors.ink : Colors.white) : s.ink;
    final r = BorderRadius.circular(PlengoRadius.pill);
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(color: selected ? bg : s.line, width: 1.5),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
