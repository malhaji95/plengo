import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../app/theme.dart';
import '../../shared/widgets/ui_kit.dart';
import '../questions/question_providers.dart';
import '../quizzes/quiz_providers.dart';

typedef ProgressQuery = ({String subjectId, String? teacherTrackId});

final progressProvider = FutureProvider.autoDispose.family<ScopeProgress, ProgressQuery>(
  (ref, q) => ref.watch(learningRepositoryProvider).progress(q.subjectId, teacherTrackId: q.teacherTrackId),
);

/// Arabic count agreement for quizzes: اختبار واحد، اختباران، 3–10 اختبارات، 11+ اختباراً.
String quizCountLabel(int n) => switch (n) {
  1 => 'اختبار واحد',
  2 => 'اختباران',
  >= 3 && <= 10 => '$n اختبارات',
  _ => '$n اختباراً',
};

/// The learning entry points of one scope (a subject's general content or a track): quizzes,
/// random practice, flashcards and the question bank, as a two-column grid of tiles.
class ScopeLearning extends ConsumerWidget {
  const ScopeLearning({
    super.key,
    required this.subjectId,
    this.teacherTrackId,
    required this.quizCount,
    required this.questionCount,
    required this.quizzesPath,
    this.deckCount,
    this.decksPath,
    this.decksLabel = 'البطاقات التعليمية',
    this.questionsPath,
    this.questionsLabel = 'بنك الأسئلة',
  });

  final String subjectId;
  final String? teacherTrackId;
  final ContentCount quizCount;
  final ContentCount questionCount;
  final String quizzesPath;
  final ContentCount? deckCount;
  final String? decksPath;
  final String decksLabel;
  final String? questionsPath;
  final String questionsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomEnabled = ref.watch(remoteConfigProvider).value?.features.randomPractice ?? true;
    String withFree(String label, ContentCount c, String free) => c.free > 0 ? '$label · ${c.free} $free' : label;
    final tiles = <Widget>[
      if (quizCount.total > 0)
        _ActionTile(
          icon: Icons.assignment_rounded,
          tint: BrandColors.tintBlue,
          title: 'الاختبارات',
          subtitle: withFree(quizCountLabel(quizCount.total), quizCount, 'مجاني'),
          onTap: () => context.go(quizzesPath),
        ),
      if (randomEnabled && questionCount.total > 0)
        _ActionTile(
          icon: Icons.shuffle_rounded,
          tint: BrandColors.tintOrange,
          title: 'تدريب عشوائي',
          subtitle: 'اختر الوحدة والنوع وعدد الأسئلة',
          onTap: () => context.push(
            Uri(
              path: Routes.randomPractice,
              queryParameters: {'subjectId': subjectId, 'teacherTrackId': ?teacherTrackId},
            ).toString(),
          ),
        ),
      if (deckCount != null && deckCount!.total > 0 && decksPath != null)
        _ActionTile(
          icon: Icons.style_rounded,
          tint: BrandColors.tintPink,
          title: decksLabel,
          subtitle: deckCountLabel(deckCount!),
          onTap: () => context.go(decksPath!),
        ),
      if (questionCount.total > 0 && questionsPath != null)
        _ActionTile(
          icon: Icons.quiz_rounded,
          tint: BrandColors.tintGreen,
          title: questionsLabel,
          subtitle: withFree(questionCountLabel(questionCount.total), questionCount, 'مجاني'),
          onTap: () => context.go(questionsPath!),
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: 10),
                    Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Arabic count agreement for decks: مجموعة واحدة، مجموعتان، 3–10 مجموعات، 11+ مجموعة.
String deckCountLabel(ContentCount c) {
  final decks = switch (c.total) {
    1 => 'مجموعة واحدة',
    2 => 'مجموعتان',
    >= 3 && <= 10 => '${c.total} مجموعات',
    _ => '${c.total} مجموعة',
  };
  return c.free > 0 ? '$decks · ${c.free} مجانية' : decks;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, tint: tint, size: 40),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The coloured header of a subject or track page: title, a secondary line and completion (§18).
class ScopeHero extends ConsumerWidget {
  const ScopeHero({super.key, required this.title, this.subtitle, required this.subjectId, this.teacherTrackId});

  final String title;
  final String? subtitle;
  final String subjectId;
  final String? teacherTrackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    final p = ref.watch(progressProvider((subjectId: subjectId, teacherTrackId: teacherTrackId))).value;
    final counts = p == null
        ? ''
        : [
            if (p.questionsTotal > 0) 'الأسئلة ${p.questionsAttempted}/${p.questionsTotal}',
            if (p.quizzesTotal > 0) 'الاختبارات ${p.quizzesCompleted}/${p.quizzesTotal}',
            if (p.flashcardsTotal > 0) 'البطاقات ${p.flashcardsStudied}/${p.flashcardsTotal}',
          ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: on)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: TextStyle(color: on.withValues(alpha: 0.9))),
                ],
                if (counts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(counts, style: TextStyle(color: on.withValues(alpha: 0.9), fontSize: 12)),
                ],
              ],
            ),
          ),
          if (p != null) ...[
            const SizedBox(width: 12),
            Semantics(
              label: 'تقدّمي ${percent(p.completionPercent)}',
              excludeSemantics: true,
              child: SizedBox.square(
                dimension: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 72,
                      child: CircularProgressIndicator(
                        value: p.completionPercent / 100,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: on,
                        backgroundColor: on.withValues(alpha: 0.25),
                      ),
                    ),
                    Text(
                      percent(p.completionPercent),
                      key: const Key('completion'),
                      style: TextStyle(color: on, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
