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
/// first (the primary entry, with progress, grouped by question category — v3 §3), then its flashcard
/// decks (pink) and quizzes (orange). Sections without content are hidden.
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
    final questions = ref.watch(questionListProvider((query: query, categoryIds: null)));
    // Categories are a refinement: when they cannot be read the card keeps its single entry.
    final categories = ref.watch(questionCategoriesProvider(query));
    final progress = ref
        .watch(progressProvider((subjectId: subjectId, teacherTrackId: null)))
        .value
        ?.lessons
        .where((l) => l.lessonId == lessonId)
        .firstOrNull;

    final loading = decks.isLoading || quizzes.isLoading || questions.isLoading || categories.isLoading;
    final failed = [decks, quizzes, questions].where((v) => v.hasError && !v.hasValue).firstOrNull;
    final deckList = decks.value ?? const [];
    final quizList = quizzes.value ?? const [];
    final questionCount = questions.value?.totalCount ?? 0;
    final groups = groupCategories(categories.value?.items ?? const []);
    final otherCount = categories.value?.uncategorized.questionCount ?? 0;
    final questionsPath = '${Routes.subjects}/$subjectId/questions?lessonId=$lessonId';
    final s = context.surface;

    Widget body;
    if (failed != null) {
      body = AsyncView(
        value: failed,
        onRetry: () {
          ref.invalidate(decksProvider(query));
          ref.invalidate(quizzesProvider(query));
          ref.invalidate(questionListProvider((query: query, categoryIds: null)));
          ref.invalidate(questionCategoriesProvider(query));
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
                groups: groups,
                otherCount: otherCount,
                onPressed: () => context.go(questionsPath),
                onCategory: (ids) => context.go('$questionsPath&categoryIds=$ids'),
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

/// The primary entry of a lesson: its questions with progress, one row per question category (children
/// nested under their parent, «أسئلة أخرى» for the rest — v3 §3) and «تابع التدريب».
class _LessonQuestionsCard extends StatelessWidget {
  const _LessonQuestionsCard({
    required this.count,
    required this.attempted,
    required this.total,
    required this.onPressed,
    this.groups = const [],
    this.otherCount = 0,
    this.onCategory,
  });

  final int count;
  final int attempted;
  final int total;
  final VoidCallback onPressed;
  final List<CategoryGroup> groups;

  /// Questions filed under no category.
  final int otherCount;

  /// Opens the questions of a category (its id, or [uncategorizedCategory]).
  final ValueChanged<String>? onCategory;

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
          if (groups.isNotEmpty && onCategory != null) ...[
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text('حسب نوع السؤال', style: PlengoType.chip.copyWith(color: blue.ink)),
            ),
            const SizedBox(height: 6),
            for (final g in groups) ...[
              CategoryRow(
                key: Key('lesson.category.${g.id}'),
                name: g.nameAr,
                count: g.questionCount,
                onTap: () => onCategory!(g.id),
              ),
              for (final c in g.children)
                CategoryRow(
                  key: Key('lesson.category.${c.id}'),
                  name: c.nameAr,
                  count: c.questionCount,
                  nested: true,
                  onTap: () => onCategory!(c.id),
                ),
            ],
            if (otherCount > 0)
              CategoryRow(
                key: const Key('lesson.category.other'),
                name: 'أسئلة أخرى',
                count: otherCount,
                onTap: () => onCategory!(uncategorizedCategory),
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

/// One question category of a lesson: its name, the question count and a chevron; [nested] rows (child
/// categories) sit indented under their parent.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.name, required this.count, required this.onTap, this.nested = false});

  final String name;
  final int count;
  final VoidCallback onTap;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final blue = PlengoColors.blue;
    final r = BorderRadius.circular(14);
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 6, start: nested ? 24 : 0),
      child: Semantics(
        button: true,
        label: '$name، ${questionCountLabel(count)}',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: s.card,
          borderRadius: r,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
                child: Row(
                  children: [
                    Icon(
                      nested ? Icons.subdirectory_arrow_left_rounded : Icons.label_rounded,
                      size: 18,
                      color: s.isDark ? s.action : blue.base,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: PlengoType.rowTitle.copyWith(
                          color: s.ink,
                          fontSize: nested ? 14 : 15,
                          fontWeight: nested ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PlengoChip(label: '$count', hue: blue),
                    Icon(Icons.chevron_right_rounded, color: s.mute),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
