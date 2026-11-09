import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/flashcard_ui.dart';
import '../offline/offline_providers.dart';
import '../quizzes/attempt_widgets.dart';
import '../quizzes/quiz_providers.dart';

typedef _AllStats = ({StatsOverview overview, StatsTrend trend, FlashcardStats flashcards});

final statsProvider = FutureProvider.autoDispose<_AllStats>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  // eagerError: the first failure itself surfaces (e.g. NETWORK_ERROR for the offline view).
  final r = await Future.wait<Object>([repo.overview(), repo.trend(), repo.flashcardStats()], eagerError: true);
  return (overview: r[0] as StatsOverview, trend: r[1] as StatsTrend, flashcards: r[2] as FlashcardStats);
});

/// Without a connection: an approximation from attempts taken on this device (spec §22.6), replaced
/// by the server's figures once they sync.
final offlineStatsProvider = FutureProvider.autoDispose<({int attempts, int answered, int correct})>((ref) async {
  final attempts = await ref.watch(localAttemptStoreProvider).submitted();
  var answered = 0;
  var correct = 0;
  for (final a in attempts) {
    answered += a.attempt.answeredCount;
    correct += a.attempt.correctCount ?? 0;
  }
  return (attempts: attempts.length, answered: answered, correct: correct);
});

final subjectStatsProvider = FutureProvider.autoDispose.family<SubjectStats, String>(
  (ref, id) => ref.watch(learningRepositoryProvider).subjectStats(id),
);

const _typeNames = {
  TypeAccuracyType.mcq: 'اختيار من متعدد',
  TypeAccuracyType.trueFalse: 'صح أو خطأ',
  TypeAccuracyType.written: 'إجابة مكتوبة',
};

String _pct(int? p) => p == null ? '—' : percent(p);

/// A chip colour for an accuracy: red below 60%, orange below 75%, green above.
PlengoHue _accuracyHue(int? p) => p == null
    ? PlengoColors.blue
    : p < 60
    ? PlengoColors.red
    : p < 75
    ? PlengoColors.orange
    : PlengoColors.green;

/// «هذا الأسبوع 78% · قبل 11 أسبوعاً 55%»: the weekly chart in words (the current week is the last).
String _weeklySummary(List<TrendWeek> weeks) {
  final current = weeks.lastOrNull?.accuracyPercent;
  if (current == null) return 'لا إجابات هذا الأسبوع بعد';
  final ago = weeks.length - 1;
  final first = weeks.first.accuracyPercent;
  if (ago == 0 || first == null) return 'هذا الأسبوع ${_pct(current)}';
  final span = arabicCount(ago, one: 'أسبوع', two: 'أسبوعين', few: 'أسابيع', many: 'أسبوعاً');
  return 'هذا الأسبوع ${_pct(current)} · قبل $span ${_pct(first)}';
}

/// إحصائياتي (spec §16.2). Redesign: V-Stats.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    if (stats.hasError && isOffline(stats.error!)) {
      return Scaffold(
        appBar: plengoAppBar(context, title: 'إحصائياتي'),
        body: ContentWidth(child: _OfflineStats(onRetry: () => ref.invalidate(statsProvider))),
      );
    }
    return Scaffold(
      appBar: plengoAppBar(context, title: 'إحصائياتي'),
      body: ContentWidth(
        child: AsyncView(
          value: stats,
          onRetry: () => ref.invalidate(statsProvider),
          data: (s) {
            final o = s.overview;
            final weeks = s.trend.weeks;
            final weekValues = [for (final w in weeks) (w.accuracyPercent ?? 0).toDouble()];
            return RefreshIndicator(
              onRefresh: () => ref.refresh(statsProvider.future),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 28),
                children: [
                  _TileGrid(
                    tiles: [
                      _Tile(label: 'أسئلة مُجابة', value: '${o.totals.answered}', hue: PlengoColors.blue),
                      _Tile(label: 'نسبة الصواب', value: _pct(o.totals.accuracyPercent), hue: PlengoColors.green),
                      _Tile(label: 'اختبارات مكتملة', value: '${o.quizzesCompleted}', hue: PlengoColors.pink),
                      _Tile(label: 'أيام الدراسة', value: '${o.studyDays}', hue: PlengoColors.yellow),
                      _Tile(label: 'السلسلة الحالية', value: '${o.currentStreak} يوم', hue: PlengoColors.orange),
                      _Tile(
                        label: 'أخطاء نشطة / متقنة',
                        value: '${o.mistakes.active} / ${o.mistakes.mastered}',
                        hue: PlengoColors.red,
                      ),
                      if (o.averageTimeMs != null)
                        _Tile(
                          label: 'متوسط الوقت للسؤال',
                          value: humanDuration(o.averageTimeMs!),
                          hue: PlengoColors.blue,
                        ),
                    ],
                  ),
                  const SizedBox(height: PlengoSpace.section),
                  _ChartCard(
                    title: 'الدقة أسبوعياً',
                    trailing: 'آخر 12 أسبوعاً',
                    summary: _weeklySummary(weeks),
                    child: BarChart(
                      values: weekValues,
                      max: 100,
                      labels: [for (final w in weeks) w.weekStart.substring(5)],
                      highlightIndex: weeks.isEmpty ? null : weeks.length - 1,
                      semantics: 'الدقة الأسبوعية',
                    ),
                  ),
                  if (o.subjects.isNotEmpty) ...[
                    const SizedBox(height: PlengoSpace.section),
                    PlengoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CardTitle('حسب المادة'),
                          for (final sub in o.subjects) _SubjectBar(sub: sub),
                        ],
                      ),
                    ),
                  ],
                  if (o.byType.isNotEmpty) ...[
                    const SizedBox(height: PlengoSpace.section),
                    PlengoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CardTitle('حسب نوع السؤال'),
                          for (final t in o.byType)
                            _ValueRow(
                              title: _typeNames[t.type] ?? '',
                              chip: PlengoChip(label: _pct(t.accuracyPercent), hue: _accuracyHue(t.accuracyPercent)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (o.weakestUnits.isNotEmpty) ...[
                    const SizedBox(height: PlengoSpace.section),
                    PlengoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CardTitle('الوحدات الأضعف'),
                          for (final u in o.weakestUnits)
                            _ValueRow(
                              leading: PlengoChip(label: _pct(u.accuracyPercent), hue: _accuracyHue(u.accuracyPercent)),
                              title: u.unitNameAr,
                              caption: u.subjectNameAr,
                              action: 'تدرّب',
                              onAction: () =>
                                  context.go('${Routes.subjects}/${u.subjectId}/questions?unitId=${u.unitId}'),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (o.mostMissed.isNotEmpty) ...[
                    const SizedBox(height: PlengoSpace.section),
                    PlengoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _CardTitle('الأسئلة الأكثر خطأ'),
                          for (final m in o.mostMissed)
                            _ValueRow(
                              title: isolateLtr(m.questionText),
                              caption: m.subjectNameAr,
                              chip: PlengoChip(
                                label: '×${m.wrongCount}',
                                hue: PlengoColors.red,
                                semanticsLabel: 'أخطأت ${m.wrongCount} مرات',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SectionHeader('البطاقات التعليمية', top: 0),
                  _FlashcardSection(stats: s.flashcards),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlashcardSection extends StatelessWidget {
  const _FlashcardSection({required this.stats});

  final FlashcardStats stats;

  @override
  Widget build(BuildContext context) {
    final f = stats;
    final forecast = [for (final d in f.forecast) d.count];
    final reviews = f.reviewsPerDay.fold(0, (sum, d) => sum + d.count);
    String forecastSummary() {
      if (forecast.isEmpty) return 'لا بطاقات مستحقة';
      final parts = ['اليوم ${forecast[0]}', if (forecast.length > 1) 'غداً ${forecast[1]}'];
      final rest = forecast.skip(2).join('، ');
      return [parts.join(' · '), if (rest.isNotEmpty) 'ثم $rest'].join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TileGrid(
          tiles: [
            _Tile(label: 'مستحقة اليوم', value: '${f.dueToday}', hue: PlengoColors.pink),
            _Tile(label: 'نسبة التذكر (30 يوماً)', value: _pct(f.retentionPercent), hue: PlengoColors.green),
            _Tile(
              label: 'جديدة / قيد التعلم',
              value: '${f.byState.newValue} / ${f.byState.learning}',
              hue: PlengoColors.blue,
            ),
            _Tile(
              label: 'مراجعة / إعادة تعلم',
              value: '${f.byState.review} / ${f.byState.relearning}',
              hue: PlengoColors.orange,
            ),
          ],
        ),
        const SizedBox(height: PlengoSpace.section),
        _ChartCard(
          title: 'المستحق خلال 7 أيام',
          summary: forecastSummary(),
          child: BarChart(
            values: [for (final c in forecast) c.toDouble()],
            labels: [for (final d in f.forecast) d.date.substring(5)],
            color: PlengoColors.pink.base,
            highlightColor: PlengoColors.pink.ink,
            highlightIndex: forecast.isEmpty ? null : 0,
            semantics: 'البطاقات المستحقة خلال الأسبوع',
          ),
        ),
        const SizedBox(height: PlengoSpace.section),
        _ChartCard(
          title: 'المراجعات يومياً',
          trailing: '30 يوماً',
          summary: 'المجموع: $reviews مراجعة في 30 يوماً',
          child: BarChart(
            values: [for (final d in f.reviewsPerDay) d.count.toDouble()],
            color: PlengoColors.green.base,
            highlightColor: PlengoColors.green.ink,
            highlightIndex: f.reviewsPerDay.isEmpty ? null : f.reviewsPerDay.length - 1,
            semantics: 'المراجعات اليومية',
          ),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: PlengoType.rowTitle.copyWith(color: s.ink)),
            ),
          ),
          if (trailing != null) Text(trailing!, style: PlengoType.caption.copyWith(color: s.mute)),
        ],
      ),
    );
  }
}

/// A chart in a card: title, the chart, and a one-line text summary (also what screen readers hear).
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.summary, required this.child, this.trailing});

  final String title;
  final String summary;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => PlengoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardTitle(title, trailing: trailing),
        ExcludeSemantics(child: child),
        const SizedBox(height: 8),
        Text(summary, style: PlengoType.caption.copyWith(color: context.surface.mute)),
      ],
    ),
  );
}

/// Accuracy of one subject: name · %, a bar in the subject colour; opens the subject's statistics.
class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.sub});

  final SubjectAccuracy sub;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = subjectHue(sub.subjectId);
    final meta = [if (sub.trackTitleAr != null) sub.trackTitleAr!, '${sub.answered} سؤال'].join(' · ');
    return Semantics(
      button: true,
      label: '${sub.subjectNameAr}، ${_pct(sub.accuracyPercent)}، $meta',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('${Routes.stats}/subjects/${sub.subjectId}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(sub.subjectNameAr, style: PlengoType.chip.copyWith(fontSize: 13, color: s.ink)),
                    ),
                    Text(
                      ' · ${_pct(sub.accuracyPercent)}',
                      style: PlengoType.chip.copyWith(fontSize: 13, color: s.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PlengoType.caption.copyWith(color: s.mute),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: s.mute),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(PlengoRadius.pill),
                  child: LinearProgressIndicator(
                    value: (sub.accuracyPercent ?? 0) / 100,
                    minHeight: 10,
                    color: hue.base,
                    backgroundColor: s.track,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A flat row in a stats card: optional leading chip, title and caption, then a chip or an action.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.title, this.caption, this.leading, this.chip, this.action, this.onAction});

  final String title;
  final String? caption;
  final Widget? leading;
  final Widget? chip;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink),
                  ),
                  if (caption != null) Text(caption!, style: PlengoType.caption.copyWith(color: s.mute)),
                ],
              ),
            ),
            if (chip != null) ...[const SizedBox(width: 8), chip!],
            if (action != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: s.action,
                  minimumSize: const Size(48, 48),
                  textStyle: PlengoType.buttonSmall.copyWith(fontSize: 13),
                ),
                child: Text(action!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Number tiles two per row (three on wide screens).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth >= 560 ? 3 : 2;
      final rows = <Widget>[];
      for (var i = 0; i < tiles.length; i += columns) {
        if (i > 0) rows.add(const SizedBox(height: 8));
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(child: i + j < tiles.length ? tiles[i + j] : const SizedBox()),
                ],
              ],
            ),
          ),
        );
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    },
  );
}

/// A coloured number tile: the value (LTR) and its label in the hue's ink.
class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.hue});

  final String label;
  final String value;
  final PlengoHue hue;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label: $value',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: PlengoType.section.copyWith(fontSize: 22, color: PlengoColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: PlengoType.caption.copyWith(color: hue.ink)),
        ],
      ),
    ),
  );
}

/// Minimal bar chart; bars run left-to-right in time order even in RTL. [highlightIndex] (e.g. the
/// current week) is drawn in [highlightColor], the others in a lighter [color]; callers add a text
/// summary so the chart never relies on colour alone.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    this.labels,
    this.max,
    required this.semantics,
    this.color,
    this.highlightColor,
    this.highlightIndex,
  });

  final List<double> values;
  final List<String>? labels;
  final double? max;
  final String semantics;
  final Color? color;
  final Color? highlightColor;
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final strong = highlightColor ?? s.action;
    final light = color ?? s.action.withValues(alpha: 0.38);
    final top = max ?? values.fold<double>(1, (m, v) => v > m ? v : m);
    return Semantics(
      label: semantics,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: labels == null ? 80 : 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, v) in values.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: top == 0 ? 0 : 76 * (v / top).clamp(0, 1),
                          decoration: BoxDecoration(
                            color: i == highlightIndex ? strong : light,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                        if (labels != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels![i],
                              style: TextStyle(
                                fontSize: 9,
                                color: s.mute,
                                fontWeight: i == highlightIndex ? FontWeight.w700 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              softWrap: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `/review/stats/subjects/:id`: accuracy by unit → lesson, by track and by type.
class SubjectStatsScreen extends ConsumerWidget {
  const SubjectStatsScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(subjectStatsProvider(subjectId));
    return Scaffold(
      appBar: plengoAppBar(context, title: stats.value?.subjectNameAr ?? 'إحصائيات المادة'),
      body: ContentWidth(
        child: AsyncView(
          value: stats,
          onRetry: () => ref.invalidate(subjectStatsProvider(subjectId)),
          data: (s) {
            Widget pct(int? p) => PlengoChip(label: _pct(p), hue: _accuracyHue(p));
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 28),
              children: [
                _TileGrid(
                  tiles: [
                    _Tile(label: 'نسبة الصواب', value: _pct(s.totals.accuracyPercent), hue: PlengoColors.green),
                    _Tile(label: 'أسئلة مُجابة', value: '${s.totals.answered}', hue: PlengoColors.blue),
                  ],
                ),
                const SizedBox(height: PlengoSpace.section),
                for (final u in s.units) ...[
                  PlengoCard(
                    padding: EdgeInsets.zero,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(u.unitNameAr, style: PlengoType.rowTitle.copyWith(color: context.surface.ink)),
                        subtitle: Text(
                          '${u.answered} سؤال',
                          style: PlengoType.caption.copyWith(color: context.surface.mute),
                        ),
                        trailing: pct(u.accuracyPercent),
                        childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                        children: [
                          for (final l in u.lessons)
                            _ValueRow(
                              title: l.lessonNameAr,
                              caption: '${l.answered} سؤال',
                              chip: pct(l.accuracyPercent),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: PlengoSpace.listGap),
                ],
                if (s.lessons.isNotEmpty)
                  PlengoCard(
                    child: Column(
                      children: [
                        for (final l in s.lessons) _ValueRow(title: l.lessonNameAr, chip: pct(l.accuracyPercent)),
                      ],
                    ),
                  ),
                if (s.tracks.isNotEmpty) ...[
                  const SizedBox(height: PlengoSpace.section),
                  PlengoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _CardTitle('مسارات المدرسين'),
                        for (final t in s.tracks) _ValueRow(title: t.trackTitleAr ?? '', chip: pct(t.accuracyPercent)),
                      ],
                    ),
                  ),
                ],
                if (s.byType.isNotEmpty) ...[
                  const SizedBox(height: PlengoSpace.section),
                  PlengoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _CardTitle('حسب نوع السؤال'),
                        for (final t in s.byType)
                          _ValueRow(title: _typeNames[t.type] ?? '', chip: pct(t.accuracyPercent)),
                      ],
                    ),
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

class _OfflineStats extends ConsumerWidget {
  const _OfflineStats({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(offlineStatsProvider).value;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 28),
      children: [
        PlengoCard(
          color: PlengoColors.orange.soft,
          child: Row(
            children: [
              const SubjectIconTile(icon: Icons.wifi_off_rounded, hue: PlengoColors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'أنت غير متصل. هذه أرقام تقريبية من الاختبارات التي أجريتها على هذا الجهاز، وتُستبدل بإحصائياتك الكاملة عند الاتصال.',
                  style: PlengoType.sub.copyWith(color: PlengoColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PlengoSpace.section),
        if (local != null)
          _TileGrid(
            tiles: [
              _Tile(label: 'اختبارات على الجهاز', value: '${local.attempts}', hue: PlengoColors.pink),
              _Tile(label: 'أسئلة مُجابة', value: '${local.answered}', hue: PlengoColors.blue),
              _Tile(
                label: 'نسبة الصواب',
                value: _pct(local.answered == 0 ? null : (local.correct * 100 / local.answered).round()),
                hue: PlengoColors.green,
              ),
            ],
          ),
        const SizedBox(height: PlengoSpace.section),
        PlengoButton(label: 'إعادة المحاولة', variant: PlengoButtonVariant.secondary, onPressed: onRetry),
      ],
    );
  }
}
