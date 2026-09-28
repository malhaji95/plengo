import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../quizzes/quiz_providers.dart';

final resumeProvider = FutureProvider.autoDispose<List<ResumeItem>>(
  (ref) => ref.watch(learningRepositoryProvider).resume(),
);

/// Home (spec §19). Phase 7 brings "متابعة التعلم" (§18); banners, countdowns, goals and streaks
/// arrive with Phase 10.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(resumeProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('متابعة التعلم', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            switch (resume) {
              AsyncData(value: final items) when items.isEmpty => Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('ابدأ من المواد'),
                  subtitle: const Text('اختر مادة وابدأ التدريب أو الاختبارات'),
                  onTap: () => context.go(Routes.subjects),
                ),
              ),
              AsyncData(value: final items) => Column(children: [for (final r in items) _ResumeTile(item: r)]),
              AsyncError() => AsyncView(
                value: resume,
                onRetry: () => ref.invalidate(resumeProvider),
                data: (_) => const SizedBox(),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ],
        ),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.item});

  final ResumeItem item;

  @override
  Widget build(BuildContext context) {
    final r = item;
    final (IconData icon, String action) = switch (r.activityType) {
      ResumeItemActivityType.quiz => (Icons.assignment_outlined, r.attemptId != null ? 'متابعة الاختبار' : 'اختبار'),
      ResumeItemActivityType.deck => (Icons.style_outlined, 'بطاقات'),
      _ => (Icons.quiz_outlined, 'أسئلة'),
    };
    final where = [
      r.subjectNameAr,
      if (r.trackTitleAr != null) r.trackTitleAr!,
      if (r.lessonNameAr != null) r.lessonNameAr!,
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(r.itemTitleAr ?? r.unitNameAr ?? r.subjectNameAr),
        subtitle: Text('$action · ${where.join(' · ')}'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          if (r.attemptId != null) {
            context.push('/attempts/${r.attemptId}');
          } else if (r.activityType == ResumeItemActivityType.quiz && r.itemId != null) {
            context.go('${Routes.quizzes}/${r.itemId}');
          } else if (r.activityType == ResumeItemActivityType.deck && r.itemId != null) {
            context.go('${Routes.decks}/${r.itemId}');
          } else if (r.lessonId != null) {
            context.go('${Routes.subjects}/${r.subjectId}/questions?lessonId=${r.lessonId}');
          } else if (r.teacherTrackId != null) {
            context.go('${Routes.tracks}/${r.teacherTrackId}');
          } else {
            context.go('${Routes.subjects}/${r.subjectId}');
          }
        },
      ),
    );
  }
}
