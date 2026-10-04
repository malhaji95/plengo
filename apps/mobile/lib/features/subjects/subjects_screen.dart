import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/ui_kit.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import 'catalog_providers.dart';
import 'placement_picker.dart';
import '../../shared/widgets/responsive.dart';

/// "المواد": every level is browsable; the student's own level and college placement are only the
/// starting point (spec §8.9).
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
          IconButton(
            key: const Key('subjects.teachers'),
            tooltip: 'المدرسون',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.go(Routes.teachers),
          ),
        ],
      ),
      body: AsyncView(
        value: levels,
        onRetry: () => ref.invalidate(levelsProvider),
        data: (items) {
          _initFrom(items, me);
          final level = items.where((l) => l.id == _levelId).firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    for (final l in items)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          key: Key('level.${l.code}'),
                          label: Text(l.nameAr),
                          selected: l.id == _levelId,
                          onSelected: (_) => _selectLevel(l.id),
                        ),
                      ),
                  ],
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
          );
        },
      ),
    );
  }

  Widget _collegeFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 220,
            child: OptionalDropdown<University>(
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
          ),
          if (_universityId != null)
            SizedBox(
              width: 220,
              child: OptionalDropdown<Faculty>(
                fieldKey: const Key('filter.faculty'),
                label: 'الكلية',
                async: ref.watch(facultiesProvider(_universityId!)),
                selectedId: _facultyId,
                idOf: (f) => f.id,
                nameOf: (f) => f.nameAr,
                onChanged: (id) => setState(() {
                  _facultyId = id;
                  _yearId = null;
                }),
              ),
            ),
          if (_facultyId != null)
            SizedBox(
              width: 220,
              child: OptionalDropdown<AcademicYear>(
                fieldKey: const Key('filter.year'),
                label: 'السنة الدراسية',
                async: ref.watch(academicYearsProvider(_facultyId!)),
                selectedId: _yearId,
                idOf: (y) => y.id,
                nameOf: (y) => y.nameAr,
                onChanged: (id) => setState(() => _yearId = id),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectList extends ConsumerWidget {
  const _SubjectList({required this.query});

  final ({String levelId, String? universityId, String? facultyId, String? academicYearId}) query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider(query));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(subjectsProvider(query).future),
      child: AsyncView(
        value: subjects,
        onRetry: () => ref.invalidate(subjectsProvider(query)),
        data: (items) => items.isEmpty
            ? ListView(children: const [EmptyState('لا توجد مواد هنا بعد', icon: Icons.menu_book_outlined)])
            : ResponsiveList(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) => _SubjectCard(subject: items[i], index: i),
              ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.index});

  final Subject subject;
  final int index;

  static const _tints = [
    BrandColors.tintYellow,
    BrandColors.tintBlue,
    BrandColors.tintGreen,
    BrandColors.tintOrange,
    BrandColors.tintPink,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: IconBadge(Icons.menu_book_rounded, tint: _tints[index % _tints.length], size: 48),
        title: Text(subject.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subject.description == null
            ? null
            : Text(subject.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.go('${Routes.subjects}/${subject.id}'),
      ),
    );
  }
}
