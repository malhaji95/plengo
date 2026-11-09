import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../subjects/catalog_providers.dart';
import '../subjects/placement_picker.dart' show OptionalDropdown, PlacementDraft;
import 'auth_widgets.dart';

/// V-Register stage picker, also used by the placement screen: one pill per real education level
/// (e.g. التاسع / البكالوريا / الجامعة); the college level reveals the optional University → Faculty → Year
/// dropdowns in a blue-soft box. Same value contract as [PlacementDraft]: choosing a parent clears its
/// children (spec §11.1).
class StagePicker extends ConsumerWidget {
  const StagePicker({super.key, required this.value, required this.onChanged});

  final PlacementDraft value;
  final ValueChanged<PlacementDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final levels = ref.watch(levelsProvider);
    final label = Text('المرحلة التعليمية', style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink));
    return levels.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: 8),
          const SkeletonGroup(
            child: Row(
              children: [
                Skeleton(width: 80, height: 44, radius: 99),
                SizedBox(width: 8),
                Skeleton(width: 100, height: 44, radius: 99),
                SizedBox(width: 8),
                Skeleton(width: 80, height: 44, radius: 99),
              ],
            ),
          ),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          AuthLink(
            label: 'تعذر تحميل المراحل التعليمية، إعادة المحاولة',
            alignment: AlignmentDirectional.centerStart,
            onPressed: () => ref.invalidate(levelsProvider),
          ),
        ],
      ),
      data: (items) {
        final level = items.where((l) => l.id == value.levelId).firstOrNull;
        return FormField<String>(
          key: const Key('placement.level'),
          initialValue: value.levelId,
          validator: (picked) => (picked ?? value.levelId) == null ? 'اختر المرحلة التعليمية' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in items)
                    PlengoPill(
                      label: l.nameAr,
                      selected: l.id == value.levelId,
                      icon: l.id == value.levelId ? Icons.check_rounded : null,
                      onTap: () {
                        if (l.id != value.levelId) {
                          onChanged((levelId: l.id, universityId: null, facultyId: null, academicYearId: null));
                        }
                        field.didChange(l.id);
                      },
                    ),
                ],
              ),
              if (field.errorText != null) FieldErrorText(message: field.errorText!),
              if (level?.isCollege ?? false) ...[
                const SizedBox(height: 14),
                _CollegeBox(value: value, onChanged: onChanged),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CollegeBox extends ConsumerWidget {
  const _CollegeBox({required this.value, required this.onChanged});

  final PlacementDraft value;
  final ValueChanged<PlacementDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    return Container(
      padding: const EdgeInsetsDirectional.all(PlengoSpace.cardPadding),
      decoration: BoxDecoration(color: s.actionSoft, borderRadius: BorderRadius.circular(PlengoRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختياري: حدّد جامعتك وكليتك وسنتك الدراسية',
            style: PlengoType.chip.copyWith(
              fontSize: 13,
              height: 1.6,
              color: s.isDark ? s.action : PlengoColors.blue.ink,
            ),
          ),
          const SizedBox(height: 10),
          OptionalDropdown<University>(
            fieldKey: const Key('placement.university'),
            label: 'الجامعة',
            async: ref.watch(universitiesProvider),
            selectedId: value.universityId,
            idOf: (u) => u.id,
            nameOf: (u) => u.nameAr,
            onChanged: (id) =>
                onChanged((levelId: value.levelId, universityId: id, facultyId: null, academicYearId: null)),
          ),
          if (value.universityId != null) ...[
            const SizedBox(height: 12),
            OptionalDropdown<Faculty>(
              fieldKey: const Key('placement.faculty'),
              label: 'الكلية',
              async: ref.watch(facultiesProvider(value.universityId!)),
              selectedId: value.facultyId,
              idOf: (f) => f.id,
              nameOf: (f) => f.nameAr,
              onChanged: (id) => onChanged((
                levelId: value.levelId,
                universityId: value.universityId,
                facultyId: id,
                academicYearId: null,
              )),
            ),
          ],
          if (value.facultyId != null) ...[
            const SizedBox(height: 12),
            OptionalDropdown<AcademicYear>(
              fieldKey: const Key('placement.year'),
              label: 'السنة الدراسية',
              async: ref.watch(academicYearsProvider(value.facultyId!)),
              selectedId: value.academicYearId,
              idOf: (y) => y.id,
              nameOf: (y) => y.nameAr,
              onChanged: (id) => onChanged((
                levelId: value.levelId,
                universityId: value.universityId,
                facultyId: value.facultyId,
                academicYearId: id,
              )),
            ),
          ],
        ],
      ),
    );
  }
}
