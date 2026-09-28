import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../quizzes/attempt_widgets.dart';
import '../offline/offline_providers.dart';
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

/// إحصائياتي (spec §16.2).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    if (stats.hasError && isOffline(stats.error!)) {
      return Scaffold(
        appBar: AppBar(title: const Text('إحصائياتي')),
        body: _OfflineStats(onRetry: () => ref.invalidate(statsProvider)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائياتي')),
      body: AsyncView(
        value: stats,
        onRetry: () => ref.invalidate(statsProvider),
        data: (s) {
          final o = s.overview;
          final text = Theme.of(context).textTheme;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(statsProvider.future),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tile(label: 'أسئلة مُجابة', value: '${o.totals.answered}'),
                        _Tile(label: 'نسبة الصواب', value: _pct(o.totals.accuracyPercent)),
                        _Tile(label: 'اختبارات مكتملة', value: '${o.quizzesCompleted}'),
                        _Tile(label: 'أيام الدراسة', value: '${o.studyDays}'),
                        _Tile(label: 'السلسلة الحالية', value: '${o.currentStreak} يوم'),
                        if (o.averageTimeMs != null)
                          _Tile(label: 'متوسط الوقت للسؤال', value: humanDuration(o.averageTimeMs!)),
                        _Tile(label: 'أخطاء نشطة / متقنة', value: '${o.mistakes.active} / ${o.mistakes.mastered}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('الدقة أسبوعياً (آخر 12 أسبوعاً)', style: text.titleSmall),
                    const SizedBox(height: 8),
                    BarChart(
                      values: [for (final w in s.trend.weeks) (w.accuracyPercent ?? 0).toDouble()],
                      max: 100,
                      labels: [for (final w in s.trend.weeks) w.weekStart.substring(5)],
                      semantics: 'الدقة الأسبوعية',
                    ),
                    if (o.subjects.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('حسب المادة', style: text.titleSmall),
                      for (final sub in o.subjects)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(sub.subjectNameAr),
                          subtitle: Text(
                            [if (sub.trackTitleAr != null) sub.trackTitleAr!, '${sub.answered} سؤال'].join(' · '),
                          ),
                          trailing: Text(_pct(sub.accuracyPercent)),
                          onTap: () => context.go('${Routes.stats}/subjects/${sub.subjectId}'),
                        ),
                    ],
                    if (o.byType.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('حسب نوع السؤال', style: text.titleSmall),
                      for (final t in o.byType)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_typeNames[t.type] ?? ''),
                          trailing: Text(_pct(t.accuracyPercent)),
                        ),
                    ],
                    if (o.weakestUnits.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('الوحدات الأضعف', style: text.titleSmall),
                      for (final u in o.weakestUnits)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(u.unitNameAr),
                          subtitle: Text(u.subjectNameAr),
                          trailing: Text(_pct(u.accuracyPercent)),
                        ),
                    ],
                    if (o.mostMissed.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('الأسئلة الأكثر خطأ', style: text.titleSmall),
                      for (final m in o.mostMissed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(isolateLtr(m.questionText), maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(m.subjectNameAr),
                          trailing: Text('×${m.wrongCount}'),
                        ),
                    ],
                    const SizedBox(height: 20),
                    Text('البطاقات التعليمية', style: text.titleSmall),
                    const SizedBox(height: 8),
                    _FlashcardSection(stats: s.flashcards),
                  ],
                ),
              ),
            ),
          );
        },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tile(label: 'مستحقة اليوم', value: '${f.dueToday}'),
            _Tile(label: 'نسبة التذكر (30 يوماً)', value: _pct(f.retentionPercent)),
            _Tile(label: 'جديدة / قيد التعلم', value: '${f.byState.newValue} / ${f.byState.learning}'),
            _Tile(label: 'مراجعة / إعادة تعلم', value: '${f.byState.review} / ${f.byState.relearning}'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('المستحق خلال 7 أيام'),
        BarChart(
          values: [for (final d in f.forecast) d.count.toDouble()],
          labels: [for (final d in f.forecast) d.date.substring(5)],
          semantics: 'البطاقات المستحقة خلال الأسبوع',
        ),
        const SizedBox(height: 12),
        const Text('المراجعات يومياً (30 يوماً)'),
        BarChart(values: [for (final d in f.reviewsPerDay) d.count.toDouble()], semantics: 'المراجعات اليومية'),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

/// Minimal bar chart; bars run left-to-right in time order even in RTL.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, this.labels, this.max, required this.semantics});

  final List<double> values;
  final List<String>? labels;
  final double? max;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
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
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: top == 0 ? 0 : 76 * (v / top).clamp(0, 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.75),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                        if (labels != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(labels![i], style: const TextStyle(fontSize: 9), maxLines: 1),
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
      appBar: AppBar(title: Text(stats.value?.subjectNameAr ?? 'إحصائيات المادة')),
      body: AsyncView(
        value: stats,
        onRetry: () => ref.invalidate(subjectStatsProvider(subjectId)),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'الدقة ${_pct(s.totals.accuracyPercent)} · ${s.totals.answered} سؤال',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final u in s.units)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(u.unitNameAr),
                  subtitle: Text('${u.answered} سؤال'),
                  trailing: Text(_pct(u.accuracyPercent)),
                  children: [
                    for (final l in u.lessons)
                      ListTile(
                        title: Text(l.lessonNameAr),
                        subtitle: Text('${l.answered} سؤال'),
                        trailing: Text(_pct(l.accuracyPercent)),
                      ),
                  ],
                ),
              ),
            for (final l in s.lessons) ListTile(title: Text(l.lessonNameAr), trailing: Text(_pct(l.accuracyPercent))),
            if (s.tracks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('مسارات المدرسين', style: Theme.of(context).textTheme.titleSmall),
              for (final t in s.tracks)
                ListTile(title: Text(t.trackTitleAr ?? ''), trailing: Text(_pct(t.accuracyPercent))),
            ],
            if (s.byType.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('حسب نوع السؤال', style: Theme.of(context).textTheme.titleSmall),
              for (final t in s.byType)
                ListTile(title: Text(_typeNames[t.type] ?? ''), trailing: Text(_pct(t.accuracyPercent))),
            ],
          ],
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
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'أنت غير متصل. هذه أرقام تقريبية من الاختبارات التي أجريتها على هذا الجهاز، وتُستبدل بإحصائياتك الكاملة عند الاتصال.',
        ),
        const SizedBox(height: 16),
        if (local != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tile(label: 'اختبارات على الجهاز', value: '${local.attempts}'),
              _Tile(label: 'أسئلة مُجابة', value: '${local.answered}'),
              _Tile(
                label: 'نسبة الصواب',
                value: _pct(local.answered == 0 ? null : (local.correct * 100 / local.answered).round()),
              ),
            ],
          ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
      ],
    );
  }
}
