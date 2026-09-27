import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import 'catalog_providers.dart';

/// A level plus optional college layers, as edited in a form. Choosing a parent clears its children.
typedef PlacementDraft = ({String? levelId, String? universityId, String? facultyId, String? academicYearId});

const emptyPlacement = (levelId: null, universityId: null, facultyId: null, academicYearId: null);

/// Level dropdown; for the college level, optional University → Faculty → Year dropdowns (spec §11.1).
class PlacementPicker extends ConsumerWidget {
  const PlacementPicker({super.key, required this.value, required this.onChanged});

  final PlacementDraft value;
  final ValueChanged<PlacementDraft> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelsProvider);
    return levels.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(levelsProvider),
        child: const Text('تعذر تحميل المراحل التعليمية، إعادة المحاولة'),
      ),
      data: (items) {
        final level = items.where((l) => l.id == value.levelId).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('placement.level'),
              isExpanded: true,
              initialValue: value.levelId,
              decoration: const InputDecoration(labelText: 'المرحلة التعليمية'),
              items: [for (final l in items) DropdownMenuItem(value: l.id, child: Text(l.nameAr))],
              onChanged: (v) => onChanged((levelId: v, universityId: null, facultyId: null, academicYearId: null)),
              validator: (v) => v == null ? 'اختر المرحلة التعليمية' : null,
            ),
            if (level?.isCollege ?? false) ...[
              const SizedBox(height: 12),
              Text('اختياري: حدّد جامعتك وكليتك وسنتك الدراسية', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              OptionalDropdown<University>(
                fieldKey: const Key('placement.university'),
                label: 'الجامعة',
                async: ref.watch(universitiesProvider),
                selectedId: value.universityId,
                idOf: (u) => u.id,
                nameOf: (u) => u.nameAr,
                onChanged: (id) => onChanged(
                  (levelId: value.levelId, universityId: id, facultyId: null, academicYearId: null),
                ),
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
                  onChanged: (id) => onChanged(
                    (levelId: value.levelId, universityId: value.universityId, facultyId: id, academicYearId: null),
                  ),
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
          ],
        );
      },
    );
  }
}

/// A dropdown whose first entry means "no selection"; items load asynchronously.
class OptionalDropdown<T> extends StatelessWidget {
  const OptionalDropdown({
    super.key,
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
  final AsyncValue<List<T>> async;
  final String? selectedId;
  final String Function(T) idOf;
  final String Function(T) nameOf;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = async.value ?? const [];
    final known = items.any((i) => idOf(i) == selectedId);
    return DropdownButtonFormField<String?>(
      key: fieldKey,
      isExpanded: true,
      initialValue: known ? selectedId : null,
      decoration: InputDecoration(labelText: label, suffixIcon: async.isLoading ? const _Spinner() : null),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('بدون تحديد')),
        for (final i in items) DropdownMenuItem<String?>(value: idOf(i), child: Text(nameOf(i))),
      ],
      onChanged: onChanged,
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)));
}
