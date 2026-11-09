import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../access/access_providers.dart';
import 'catalog_providers.dart';
import 'scope_widgets.dart';

/// "المواد" (V-Subjects): every level is browsable; the student's own level and college placement
/// are only the starting point (spec §8.9). Locked subjects carry a red «مقفل» chip (DECISIONS #1).
class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String? _levelId;
  String? _universityId;
  String? _facultyId;
  String? _yearId;
  bool _initialized = false;

  void _initFrom(List<EducationLevel> levels, Me? me) {
    if (_initialized || levels.isEmpty) return;
    _initialized = true;
    final own = levels.where((l) => l.id == me?.educationLevelId).firstOrNull;
    _levelId = (own ?? levels.first).id;
    if (own?.isCollege ?? false) {
      _universityId = me?.universityId;
      _facultyId = me?.facultyId;
      _yearId = me?.academicYearId;
    }
  }

  void _selectLevel(String id) => setState(() {
    _levelId = id;
    _universityId = _facultyId = _yearId = null;
  });

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(levelsProvider);
    final me = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المواد'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: PlengoButton(
                key: const Key('subjects.teachers'),
                label: 'المدرسون',
                icon: Icons.groups_rounded,
                variant: PlengoButtonVariant.secondary,
                size: PlengoButtonSize.small,
                onPressed: () => context.go(Routes.teachers),
              ),
            ),
          ),
        ],
      ),
      body: AsyncView(
        value: levels,
        onRetry: () => ref.invalidate(levelsProvider),
        data: (items) {
          _initFrom(items, me);
          final level = items.where((l) => l.id == _levelId).firstOrNull;
          return ContentWidthBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  container: true,
                  label: 'المرحلة',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 8),
                    child: Row(
                      children: [
                        for (final (i, l) in items.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          PlengoPill(
                            key: Key('level.${l.code}'),
                            label: l.nameAr,
                            selected: l.id == _levelId,
                            onTap: () => _selectLevel(l.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (level?.isCollege ?? false) _collegeFilter(),
                Expanded(
                  child: level == null
                      ? const SizedBox.shrink()
                      : _SubjectList(
                          query: (
                            levelId: level.id,
                            universityId: _universityId,
                            facultyId: _facultyId,
                            academicYearId: _yearId,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// University → faculty → year as three compact selects; a child stays disabled until its parent
  /// is chosen. With large text they stack.
  Widget _collegeFilter() {
    final selects = [
      _CompactSelect<University>(
        fieldKey: const Key('filter.university'),
        label: 'الجامعة',
        async: ref.watch(universitiesProvider),
        selectedId: _universityId,
        idOf: (u) => u.id,
        nameOf: (u) => u.nameAr,
        onChanged: (id) => setState(() {
          _universityId = id;
          _facultyId = _yearId = null;
        }),
      ),
      _CompactSelect<Faculty>(
        fieldKey: const Key('filter.faculty'),
        label: 'الكلية',
        async: _universityId == null ? null : ref.watch(facultiesProvider(_universityId!)),
        selectedId: _facultyId,
        idOf: (f) => f.id,
        nameOf: (f) => f.nameAr,
        onChanged: (id) => setState(() {
          _facultyId = id;
          _yearId = null;
        }),
      ),
      _CompactSelect<AcademicYear>(
        fieldKey: const Key('filter.year'),
        label: 'السنة الدراسية',
        async: _facultyId == null ? null : ref.watch(academicYearsProvider(_facultyId!)),
        selectedId: _yearId,
        idOf: (y) => y.id,
        nameOf: (y) => y.nameAr,
        onChanged: (id) => setState(() => _yearId = id),
      ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 8),
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (box.maxWidth / 3 < 112 * scale) {
            return Column(
              children: [
                for (final (i, s) in selects.indexed) ...[if (i > 0) const SizedBox(height: 6), s],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, s) in selects.indexed) ...[if (i > 0) const SizedBox(width: 6), Expanded(child: s)],
            ],
          );
        },
      ),
    );
  }
}

/// A small dropdown whose first entry means "no selection"; [async] null means its parent is not
/// chosen yet, so it is disabled.
class _CompactSelect<T> extends StatelessWidget {
  const _CompactSelect({
    required this.fieldKey,
    required this.label,
    required this.async,
    required this.selectedId,
    required this.idOf,
    required this.nameOf,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final AsyncValue<List<T>>? async;
  final String? selectedId;
  final String Function(T) idOf;
  final String Function(T) nameOf;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final items = async?.value ?? const [];
    final known = items.any((i) => idOf(i) == selectedId);
    final style = PlengoType.sub.copyWith(fontSize: 13, color: s.ink, height: 1.3, fontWeight: FontWeight.w500);
    return DropdownButtonFormField<String?>(
      key: fieldKey,
      isExpanded: true,
      initialValue: known ? selectedId : null,
      style: style,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 14),
        suffixIcon: async?.isLoading ?? false
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('بدون تحديد', overflow: TextOverflow.ellipsis, style: style),
        ),
        for (final i in items)
          DropdownMenuItem<String?>(
            value: idOf(i),
            child: Text(nameOf(i), overflow: TextOverflow.ellipsis, style: style),
          ),
      ],
      onChanged: async == null ? null : onChanged,
    );
  }
}

class _SubjectList extends ConsumerWidget {
  const _SubjectList({required this.query});

  final ({String levelId, String? universityId, String? facultyId, String? academicYearId}) query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider(query));
    final redeem = ref.watch(couponRedemptionProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(subjectsProvider(query).future),
      child: AsyncView(
        value: subjects,
        onRetry: () => ref.invalidate(subjectsProvider(query)),
        data: (items) => LayoutBuilder(
          builder: (context, box) {
            // Phones: one column; wide screens: a grid whose rows keep their tallest item (spec §24).
            final columns = ResponsiveList.columnsFor(box.maxWidth - 2 * PlengoSpace.screen);
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 28),
              children: [
                if (items.isEmpty)
                  const PlengoEmptyState(title: 'لا توجد مواد هنا بعد', icon: Icons.menu_book_outlined)
                else
                  for (var r = 0; r < items.length; r += columns)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                      child: columns == 1
                          ? _SubjectRow(subject: items[r])
                          : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var c = 0; c < columns; c++) ...[
                                    if (c > 0) const SizedBox(width: PlengoSpace.listGap),
                                    Expanded(
                                      child: r + c < items.length
                                          ? _SubjectRow(subject: items[r + c])
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                if (redeem) ...[
                  const SizedBox(height: 6),
                  ListRow(
                    key: const Key('subjects.redeem'),
                    background: PlengoColors.yellow.soft,
                    leading: const SubjectIconTile(icon: Icons.vpn_key_rounded, hue: PlengoColors.yellow),
                    title: 'لديك كود تفعيل؟',
                    caption: 'افتح مادة أو مسار مدرّس',
                    onTap: () => context.push(Routes.redeem),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});

  final CatalogSubject subject;

  @override
  Widget build(BuildContext context) => ListRow(
    key: Key('subject.${subject.id}'),
    leading: SubjectIconTile.forSubject(subject.id, icon: Icons.menu_book_rounded),
    title: subject.nameAr,
    caption: subject.description,
    trailing: subject.hasAccess ? null : const LockedChip(),
    onTap: () => context.go('${Routes.subjects}/${subject.id}'),
  );
}
