import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/form_widgets.dart';
import '../subjects/catalog_providers.dart';
import '../subjects/placement_picker.dart';

/// Change the profile level and college placement at any time (spec §8.9). It only sets the
/// defaults of the Subjects tab; every level stays browsable.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final _form = GlobalKey<FormState>();
  late PlacementDraft _draft;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final me = ref.read(authControllerProvider).value;
    _draft = (
      levelId: me?.educationLevelId,
      universityId: me?.universityId,
      facultyId: me?.facultyId,
      academicYearId: me?.academicYearId,
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final me = await ref.read(catalogRepositoryProvider).updatePlacement((
        levelId: _draft.levelId!,
        universityId: _draft.universityId,
        facultyId: _draft.facultyId,
        academicYearId: _draft.academicYearId,
      ));
      ref.read(authControllerProvider.notifier).setMe(me);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المرحلة التعليمية')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المرحلة التعليمية')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('تحدد مرحلتك ما يظهر أولاً في تبويب المواد، ويمكنك تصفح كل المراحل في أي وقت.'),
                  const SizedBox(height: 16),
                  PlacementPicker(value: _draft, onChanged: (v) => setState(() => _draft = v)),
                  const SizedBox(height: 16),
                  ErrorBanner(_error),
                  const SizedBox(height: 16),
                  SubmitButton(key: const Key('placement.save'), label: 'حفظ', busy: _busy, onPressed: _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
