import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../questions/question_view.dart';
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
    final s = context.surface;
    final outline = ref.watch(subjectOutlineProvider(widget.subjectId));
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: PlengoType.rowTitle.copyWith(color: s.ink)),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: const Text('تدريب عشوائي'),
      ),
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
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      const SubjectIconTile(icon: Icons.shuffle_rounded, hue: PlengoColors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(o.subject.nameAr, style: PlengoType.section.copyWith(color: s.ink)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PlengoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (o.units.isNotEmpty) ...[
                          DropdownButtonFormField<String?>(
                            initialValue: _unitId,
                            isExpanded: true,
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
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'الدرس'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل الدروس')),
                              for (final l in lessons) DropdownMenuItem(value: l.id, child: Text(l.titleAr)),
                            ],
                            onChanged: (v) => setState(() => _lessonId = v),
                          ),
                          const SizedBox(height: 16),
                        ],
                        label('أنواع الأسئلة'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in AttemptFiltersTypes.values)
                              _TypeToggle(
                                label: _typeLabels[t]!,
                                selected: _types.contains(t),
                                onTap: () => setState(() => _types.contains(t) ? _types.remove(t) : _types.add(t)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        label('عدد الأسئلة: ${_count.round()}'),
                        Slider(
                          value: _count,
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: '${_count.round()}',
                          activeColor: s.action,
                          inactiveColor: s.track,
                          semanticFormatterCallback: (v) => '${v.round()} سؤالاً',
                          onChanged: (v) => setState(() => _count = v),
                        ),
                        const SizedBox(height: 8),
                        SegmentedControl<StartAttemptRequestMode>(
                          segments: const [
                            PlengoOption(StartAttemptRequestMode.practice, 'تدريب'),
                            PlengoOption(StartAttemptRequestMode.exam, 'امتحان'),
                          ],
                          selected: _mode,
                          onChanged: (m) => setState(() => _mode = m),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[InlineError(_error), const SizedBox(height: 12)],
                  PlengoButton(label: 'ابدأ', busy: _busy, onPressed: _busy ? null : _start),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A multi-select pill: ink fill + ✓ when on (dark mode: yellow), never colour alone.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.label, required this.selected, required this.onTap});

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
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: PlengoType.family,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
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
