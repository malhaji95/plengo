import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A level plus optional college layers, as edited in a form. Choosing a parent clears its children.
typedef PlacementDraft = ({String? levelId, String? universityId, String? facultyId, String? academicYearId});

const emptyPlacement = (levelId: null, universityId: null, facultyId: null, academicYearId: null);

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
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(14),
    child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
  );
}
