import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/flashcard_ui.dart';
import '../quizzes/quiz_providers.dart';

final mistakesProvider = FutureProvider.autoDispose.family<MistakeList, MistakeFilterStatus>(
  (ref, status) => ref.watch(learningRepositoryProvider).mistakes(status: status),
);

/// Mistake bank (مراجعة الأخطاء, spec §16.1): wrong answers grouped by subject and unit, with
/// "اختبر أخطائي". Questions the student can no longer open are hidden by the server.
class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  var _status = MistakeFilterStatus.active;
  String? _subjectId;
  String? _unitId;
  MistakeType? _type;

  static const _typeLabels = {
    MistakeType.mcq: 'اختيار من متعدد',
    MistakeType.trueFalse: 'صح أو خطأ',
    MistakeType.written: 'إجابة مكتوبة',
  };

  Future<void> _test(MistakeList list) async {
    var count = list.activeCount.clamp(1, 20).toDouble();
    var mode = StartAttemptRequestMode.practice;
    final go = await showPlengoSheet<bool>(
      context: context,
      title: 'اختبر أخطائي',
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('عدد الأسئلة: ${count.round()}', style: PlengoType.rowTitle.copyWith(color: context.surface.ink)),
            if (list.activeCount > 1)
              Slider(
                value: count,
                min: 1,
                max: list.activeCount.clamp(1, 100).toDouble(),
                label: '${count.round()}',
                onChanged: (v) => setSheet(() => count = v),
              ),
            const SizedBox(height: 8),
            SegmentedControl<StartAttemptRequestMode>(
              segments: const [
                PlengoOption(StartAttemptRequestMode.practice, 'تدريب'),
                PlengoOption(StartAttemptRequestMode.exam, 'امتحان'),
              ],
              selected: mode,
              onChanged: (m) => setSheet(() => mode = m),
            ),
            const SizedBox(height: 16),
            PlengoButton(label: 'ابدأ', onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    try {
      final a = await startAttempt(
        ref.read(learningRepositoryProvider),
        source: StartAttemptRequestSource.mistakes,
        mode: mode,
        filters: AttemptFilters(
          subjectId: _subjectId,
          unitId: _unitId,
          types: _type == null ? null : [AttemptFiltersTypes.values.byName(_type!.name)],
          count: count.round(),
        ),
      );
      if (!mounted) return;
      await context.push('/attempts/${a.attempt.id}');
      ref.invalidate(mistakesProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mistakes = ref.watch(mistakesProvider(_status));
    final s = context.surface;
    return Scaffold(
      appBar: plengoAppBar(context, title: 'مراجعة الأخطاء'),
      body: ContentWidth(
        child: AsyncView(
          value: mistakes,
          onRetry: () => ref.invalidate(mistakesProvider(_status)),
          data: (list) {
            final subjects = <String, String>{for (final m in list.items) m.subjectId: m.subjectNameAr};
            final inSubject = list.items.where((m) => _subjectId == null || m.subjectId == _subjectId).toList();
            final units = <String, String>{
              for (final m in inSubject)
                if (m.unitId != null) m.unitId!: m.unitNameAr ?? '',
            };
            final types = {for (final m in inSubject) m.type};
            final shown = inSubject
                .where((m) => (_unitId == null || m.unitId == _unitId) && (_type == null || m.type == _type))
                .toList();
            // Group by subject, then unit (or the lesson directly under the subject).
            final groups = <String, List<Mistake>>{};
            for (final m in shown) {
              final key = [
                if (_subjectId == null) m.subjectNameAr,
                if (m.trackTitleAr != null) m.trackTitleAr!,
                m.unitNameAr ?? m.lessonNameAr ?? 'أسئلة عامة',
              ].join(' · ');
              (groups[key] ??= []).add(m);
            }
            final canTest = _status == MistakeFilterStatus.active && shown.isNotEmpty;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: PlengoSpace.screen),
                        child: SegmentedControl<MistakeFilterStatus>(
                          segments: [
                            PlengoOption(MistakeFilterStatus.active, 'نشطة (${list.activeCount})'),
                            PlengoOption(MistakeFilterStatus.mastered, 'متقنة (${list.masteredCount})'),
                          ],
                          selected: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ),
                      if (subjects.length > 1) ...[
                        const SizedBox(height: 12),
                        PillSelector<String?>(
                          options: [
                            const PlengoOption(null, 'كل المواد', icon: Icons.filter_list_rounded),
                            for (final MapEntry(key: id, value: name) in subjects.entries) PlengoOption(id, name),
                          ],
                          selected: _subjectId,
                          onSelected: (id) => setState(() {
                            _subjectId = id;
                            _unitId = null;
                          }),
                        ),
                      ],
                      // Units once a subject is chosen (or when there is only one subject).
                      if ((_subjectId != null || subjects.length == 1) && units.length > 1) ...[
                        const SizedBox(height: 8),
                        PillSelector<String?>(
                          options: [
                            const PlengoOption(null, 'كل الوحدات'),
                            for (final MapEntry(key: id, value: name) in units.entries) PlengoOption(id, name),
                          ],
                          selected: _unitId,
                          onSelected: (id) => setState(() => _unitId = id),
                        ),
                      ],
                      if (types.length > 1) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: PlengoSpace.screen),
                          child: Row(
                            spacing: 8,
                            children: [
                              for (final t in MistakeType.values.where(types.contains))
                                // A toggle: tap again to show every type.
                                PlengoPill(
                                  label: _typeLabels[t]!,
                                  selected: _type == t,
                                  icon: _type == t ? Icons.check_rounded : null,
                                  onTap: () => setState(() => _type = _type == t ? null : t),
                                ),
                            ],
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: PlengoSpace.screen),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_status == MistakeFilterStatus.active) ...[
                              const SizedBox(height: 12),
                              Text(
                                'يُتقن السؤال بعد ${list.masteryStreak} إجابات صحيحة متتالية',
                                style: PlengoType.caption.copyWith(color: s.mute),
                              ),
                            ],
                            const SizedBox(height: 4),
                            if (shown.isEmpty)
                              EmptyState(
                                _status == MistakeFilterStatus.active ? 'لا أخطاء لمراجعتها' : 'لا أسئلة متقنة بعد',
                                icon: Icons.task_alt_rounded,
                              ),
                            for (final MapEntry(key: title, value: items) in groups.entries) ...[
                              SectionHeader(title, top: 14),
                              for (final m in items) ...[
                                _MistakeCard(mistake: m, typeLabel: _typeLabels[m.type]),
                                const SizedBox(height: PlengoSpace.listGap),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (canTest)
                  BottomPanel(
                    children: [
                      PlengoButton(label: 'اختبر أخطائي', icon: Icons.play_arrow_rounded, onPressed: () => _test(list)),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// «أخطأت مرة» / «مرتين» / «3 مرات».
String _wrongLabel(int n) => 'أخطأت ${arabicCount(n, one: 'مرة', two: 'مرتين', few: 'مرات', many: 'مرة')}';

/// One mistake: subject and type chips, the question, «أخطأت N مرات · صحيحة متتالية: k» and «تدرّب»
/// (the related lesson or unit, §16.1).
class _MistakeCard extends ConsumerWidget {
  const _MistakeCard({required this.mistake, required this.typeLabel});

  final Mistake mistake;
  final String? typeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = mistake;
    final s = context.surface;
    final hue = subjectHue(m.subjectId);
    void practise() => context.go(
      m.lessonId != null
          ? '${Routes.subjects}/${m.subjectId}/questions?lessonId=${m.lessonId}'
          : m.unitId != null
          ? '${Routes.subjects}/${m.subjectId}/questions?unitId=${m.unitId}'
          : m.teacherTrackId != null
          ? '${Routes.tracks}/${m.teacherTrackId}/questions'
          : '${Routes.subjects}/${m.subjectId}/questions',
    );
    return PlengoCard(
      onTap: practise,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PlengoChip(label: m.subjectNameAr, hue: hue),
                    if (typeLabel != null) PlengoChip(label: typeLabel!, hue: PlengoColors.blue),
                  ],
                ),
              ),
              if (m.status == MistakeStatus.active)
                IconButton(
                  tooltip: 'إزالة من الأخطاء',
                  color: s.mute,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    try {
                      await ref.read(learningRepositoryProvider).removeMistake(m.questionId);
                      ref.invalidate(mistakesProvider);
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                )
              else
                const SizedBox(height: 48),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Text(
              isolateLtr(m.questionText),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: PlengoType.rowTitle.copyWith(color: s.ink),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: _wrongLabel(m.wrongCount),
                        style: TextStyle(color: hueText(context, PlengoColors.red), fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' · صحيحة متتالية: ${m.correctStreak}'),
                    ],
                  ),
                  style: PlengoType.caption.copyWith(color: s.mute),
                ),
              ),
              TextButton(
                onPressed: practise,
                style: TextButton.styleFrom(
                  foregroundColor: s.action,
                  minimumSize: const Size(48, 48),
                  textStyle: PlengoType.buttonSmall.copyWith(fontSize: 13),
                ),
                child: const Text('تدرّب'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
