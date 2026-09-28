import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/form_widgets.dart';
import '../subjects/catalog_providers.dart';
import 'quiz_providers.dart';

const _typeLabels = {
  AttemptFiltersTypes.mcq: 'اختيار من متعدد',
  AttemptFiltersTypes.trueFalse: 'صح أو خطأ',
  AttemptFiltersTypes.written: 'إجابة مكتوبة',
};

/// Random practice (spec §15.3): "20 random questions, Grade 12 Physics, Unit 2, types X". The
/// server draws only published questions the student can open.
class RandomPracticeScreen extends ConsumerStatefulWidget {
  const RandomPracticeScreen({super.key, required this.subjectId, this.teacherTrackId});

  final String subjectId;
  final String? teacherTrackId;

  @override
  ConsumerState<RandomPracticeScreen> createState() => _RandomPracticeScreenState();
}

class _RandomPracticeScreenState extends ConsumerState<RandomPracticeScreen> {
  String? _unitId;
  String? _lessonId;
  final _types = <AttemptFiltersTypes>{};
  double _count = 20;
  var _mode = StartAttemptRequestMode.practice;
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await startAttempt(
        ref.read(learningRepositoryProvider),
        source: StartAttemptRequestSource.random,
        mode: _mode,
        filters: AttemptFilters(
          subjectId: widget.subjectId,
          teacherTrackId: widget.teacherTrackId,
          unitId: _unitId,
          lessonId: _lessonId,
          types: _types.isEmpty ? null : _types.toList(),
          count: _count.round(),
        ),
      );
      if (mounted) context.pushReplacement('/attempts/${a.attempt.id}');
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
    final outline = ref.watch(subjectOutlineProvider(widget.subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('تدريب عشوائي')),
      body: AsyncView(
        value: outline,
        onRetry: () => ref.invalidate(subjectOutlineProvider(widget.subjectId)),
        data: (o) {
          final lessons = [
            ...o.units.where((u) => _unitId == null || u.id == _unitId).expand((u) => u.lessons),
            if (_unitId == null) ...o.lessons,
          ];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(o.subject.nameAr, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (o.units.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: _unitId,
                      decoration: const InputDecoration(labelText: 'الوحدة'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('كل الوحدات')),
                        for (final u in o.units) DropdownMenuItem(value: u.id, child: Text(u.titleAr)),
                      ],
                      onChanged: (v) => setState(() {
                        _unitId = v;
                        _lessonId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (lessons.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      key: ValueKey(_unitId),
                      initialValue: _lessonId,
                      decoration: const InputDecoration(labelText: 'الدرس'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('كل الدروس')),
                        for (final l in lessons) DropdownMenuItem(value: l.id, child: Text(l.titleAr)),
                      ],
                      onChanged: (v) => setState(() => _lessonId = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('أنواع الأسئلة'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in AttemptFiltersTypes.values)
                        FilterChip(
                          label: Text(_typeLabels[t]!),
                          selected: _types.contains(t),
                          onSelected: (on) => setState(() => on ? _types.add(t) : _types.remove(t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('عدد الأسئلة: ${_count.round()}'),
                  Slider(
                    value: _count,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${_count.round()}',
                    onChanged: (v) => setState(() => _count = v),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<StartAttemptRequestMode>(
                    segments: const [
                      ButtonSegment(value: StartAttemptRequestMode.practice, label: Text('تدريب')),
                      ButtonSegment(value: StartAttemptRequestMode.exam, label: Text('امتحان')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 16),
                  ErrorBanner(_error),
                  SubmitButton(label: 'ابدأ', busy: _busy, onPressed: _start),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
