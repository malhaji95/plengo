import 'package:flutter/material.dart';

import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import 'diagram_widgets.dart';

/// The score of a set of checked diagrams.
typedef DiagramScore = ({int diagrams, int correct, int total, int percent});

DiagramScore diagramScore(List<DiagramCheckResult> results) {
  final correct = results.fold(0, (n, r) => n + r.correctCount);
  final total = results.fold(0, (n, r) => n + r.totalCount);
  return (
    diagrams: results.length,
    correct: correct,
    total: total,
    percent: total == 0 ? 0 : (correct * 100 / total).round(),
  );
}

/// «تم إنهاء التدريب!»: the score %, correct answers and diagrams, «إعادة التدريب» (same diagrams) and
/// «تدريب آخر» (back to the setup), then each diagram with its labels (expandable).
class DiagramResults extends StatelessWidget {
  const DiagramResults({
    super.key,
    required this.diagrams,
    required this.results,
    required this.onRetry,
    required this.onAnother,
  });

  final List<PracticeDiagram> diagrams;
  final List<DiagramCheckResult> results;
  final VoidCallback onRetry;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final score = diagramScore(results);
    final great = score.percent >= 60;
    final titles = {for (final d in diagrams) d.id: d.titleAr};
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
      children: [
        const DiagramSteps(current: 2),
        const SizedBox(height: 20),
        Center(
          child: StateIllustration(
            icon: great ? Icons.emoji_events_rounded : Icons.track_changes_rounded,
            hue: great ? PlengoColors.yellow : PlengoColors.blue,
            size: 110,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'تم إنهاء التدريب!',
            textAlign: TextAlign.center,
            style: PlengoType.title.copyWith(color: s.ink, fontSize: 24),
          ),
        ),
        const SizedBox(height: 16),
        PlengoCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    key: const Key('diagrams.result.percent'),
                    icon: Icons.bar_chart_rounded,
                    hue: PlengoColors.blue,
                    value: '${score.percent}%',
                    label: 'النتيجة',
                  ),
                ),
                VerticalDivider(color: s.line, width: 1),
                Expanded(
                  child: _Stat(
                    key: const Key('diagrams.result.correct'),
                    icon: Icons.check_circle_outline_rounded,
                    hue: PlengoColors.green,
                    value: '${score.correct} / ${score.total}',
                    label: 'الإجابات الصحيحة',
                  ),
                ),
                VerticalDivider(color: s.line, width: 1),
                Expanded(
                  child: _Stat(
                    key: const Key('diagrams.result.count'),
                    icon: Icons.image_outlined,
                    hue: PlengoColors.orange,
                    value: '${score.diagrams}',
                    label: 'الرسومات',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PlengoButton(
          key: const Key('diagrams.retry'),
          label: 'إعادة التدريب',
          icon: Icons.replay_rounded,
          onPressed: onRetry,
        ),
        const SizedBox(height: 10),
        PlengoButton(
          key: const Key('diagrams.another'),
          label: 'تدريب آخر',
          icon: Icons.layers_outlined,
          variant: PlengoButtonVariant.secondary,
          onPressed: onAnother,
        ),
        const SizedBox(height: 20),
        Text('الرسومات', style: PlengoType.section.copyWith(color: s.ink)),
        const SizedBox(height: 8),
        for (final r in results) ...[
          PlengoCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: Key('diagrams.result.${r.diagramId}'),
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
                iconColor: s.mute,
                collapsedIconColor: s.mute,
                title: Text(titles[r.diagramId] ?? '', style: PlengoType.rowTitle.copyWith(color: s.ink)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PlengoChip(
                      label: '${r.correctCount} من ${r.totalCount} صحيحة',
                      hue: r.correctCount == r.totalCount ? PlengoColors.green : PlengoColors.orange,
                    ),
                  ),
                ),
                children: [
                  for (final l in [...r.labels]..sort((a, b) => a.number.compareTo(b.number))) ...[
                    DiagramLabelVerdict(result: l),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: PlengoSpace.listGap),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.icon, required this.hue, required this.value, required this.label});

  final IconData icon;
  final PlengoHue hue;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: s.isDark ? hue.base : hue.ink, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: PlengoType.section.copyWith(color: s.ink),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: PlengoType.caption.copyWith(color: s.mute, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
