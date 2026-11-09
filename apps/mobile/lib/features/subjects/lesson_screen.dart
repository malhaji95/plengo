import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/decks_screen.dart';
import '../flashcards/flashcard_providers.dart';
import '../learning/scope_learning.dart';
import '../questions/question_providers.dart';
import '../quizzes/quiz_providers.dart';
import '../quizzes/quizzes_screen.dart';
import 'catalog_providers.dart';
import 'scope_widgets.dart';

/// Everything placed in one lesson of a subject's general content (V-Lesson): the lesson questions
/// first (the primary entry, with progress), then its flashcard decks (pink) and quizzes (orange).
/// Sections without content are hidden.
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.subjectId, required this.lessonId});

  final String subjectId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    final lessons = [...?outline?.lessons, ...?outline?.units.expand((u) => u.lessons)];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;
    final unit = outline?.units.where((u) => u.lessons.any((l) => l.id == lessonId)).firstOrNull;
    final query = (subjectId: subjectId, teacherTrackId: null, unitId: null, lessonId: lessonId);
    final decks = ref.watch(decksProvider(query));
    final quizzes = ref.watch(quizzesProvider(query));
    final questions = ref.watch(questionListProvider(query));
    final progress = ref
        .watch(progressProvider((subjectId: subjectId, teacherTrackId: null)))
        .value
        ?.lessons
        .where((l) => l.lessonId == lessonId)
        .firstOrNull;

    final loading = decks.isLoading || quizzes.isLoading || questions.isLoading;
    final failed = [decks, quizzes, questions].where((v) => v.hasError && !v.hasValue).firstOrNull;
    final deckList = decks.value ?? const [];
    final quizList = quizzes.value ?? const [];
    final questionCount = questions.value?.totalCount ?? 0;
    final s = context.surface;

    Widget body;
    if (failed != null) {
      body = AsyncView(
        value: failed,
        onRetry: () {
          ref.invalidate(decksProvider(query));
          ref.invalidate(quizzesProvider(query));
          ref.invalidate(questionListProvider(query));
        },
        data: (_) => const SizedBox(),
      );
    } else if (loading) {
      body = const Align(alignment: Alignment.topCenter, child: PlengoLoadingSkeleton());
    } else if (deckList.isEmpty && quizList.isEmpty && questionCount == 0) {
      body = const PlengoEmptyState(title: 'لا يوجد محتوى في هذا الدرس بعد', icon: Icons.article_outlined);
    } else {
      final where = [?outline?.subject.nameAr, ?unit?.titleAr].join(' · ');
      body = ContentWidthBox(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 28),
          children: [
            if (where.isNotEmpty)
              Text(where, style: PlengoType.chip.copyWith(color: s.isDark ? s.action : PlengoColors.blue.ink)),
            if (lesson != null)
              Semantics(
                header: true,
                child: Text(lesson.titleAr, style: PlengoType.title.copyWith(color: s.ink)),
              ),
            const SizedBox(height: PlengoSpace.section),
            if (questionCount > 0) ...[
              _LessonQuestionsCard(
                count: questionCount,
                attempted: progress?.questionsAttempted ?? 0,
                total: progress?.questionsTotal ?? questionCount,
                onPressed: () => context.go('${Routes.subjects}/$subjectId/questions?lessonId=$lessonId'),
              ),
              const SizedBox(height: PlengoSpace.section),
            ],
            if (deckList.isNotEmpty) ...[
              const SectionHeader('البطاقات التعليمية', top: 0),
              for (final d in deckList)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                  child: LessonDeckRow(deck: d),
                ),
              const SizedBox(height: 6),
            ],
            if (quizList.isNotEmpty) ...[
              const SectionHeader('الاختبارات', top: 0),
              for (final q in quizList)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: PlengoSpace.listGap),
                  child: QuizTile(quiz: q),
                ),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth),
      body: body,
    );
  }
}

/// The primary entry of a lesson: its questions with progress and «تابع التدريب».
class _LessonQuestionsCard extends StatelessWidget {
  const _LessonQuestionsCard({
    required this.count,
    required this.attempted,
    required this.total,
    required this.onPressed,
  });

  final int count;
  final int attempted;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blue = PlengoColors.blue;
    final done = total == 0 ? 0.0 : (attempted / total).clamp(0.0, 1.0);
    return PlengoCard(
      color: blue.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                SubjectIconTile(icon: Icons.quiz_rounded, hue: blue, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أسئلة الدرس', style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink)),
                      Text(
                        [questionCountLabel(count), if (attempted > 0) 'أجبت عن $attempted'].join(' · '),
                        style: PlengoType.caption.copyWith(color: blue.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (attempted > 0) ...[
            const SizedBox(height: 12),
            PlengoProgressBar(
              value: done,
              label: '$attempted/$total',
              color: blue.base,
              trackColor: Colors.white,
              labelColor: PlengoColors.ink,
              semanticsLabel: 'أجبت عن $attempted من $total',
            ),
          ],
          const SizedBox(height: 12),
          PlengoButton(
            label: attempted > 0 ? 'تابع التدريب' : 'ابدأ التدريب',
            icon: Icons.play_arrow_rounded,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// An official deck of a lesson: a pink row with its card count; locked decks show «مقفل».
class LessonDeckRow extends StatelessWidget {
  const LessonDeckRow({super.key, required this.deck});

  final StudentDeck deck;

  @override
  Widget build(BuildContext context) => ListRow(
    icon: Icons.style_rounded,
    hue: PlengoColors.pink,
    title: deck.titleAr,
    caption: [cardCountLabel(deck.cardCount), if (deck.isFree) 'مجانية'].join(' · '),
    trailing: deck.locked ? const LockedChip() : null,
    onTap: () => context.go('${Routes.decks}/${deck.id}'),
  );
}
