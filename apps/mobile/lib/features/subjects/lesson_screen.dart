import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/decks_screen.dart';
import '../flashcards/flashcard_providers.dart';
import '../questions/question_providers.dart';
import '../quizzes/quiz_providers.dart';
import '../quizzes/quizzes_screen.dart';
import 'catalog_providers.dart';

/// Everything placed in one lesson of a subject's general content: its flashcard decks, quizzes
/// and questions. Sections without content are hidden.
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.subjectId, required this.lessonId});

  final String subjectId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    final lessons = [...?outline?.lessons, ...?outline?.units.expand((u) => u.lessons)];
    final title = lessons.where((l) => l.id == lessonId).firstOrNull?.titleAr ?? '';
    final query = (subjectId: subjectId, teacherTrackId: null, unitId: null, lessonId: lessonId);
    final decks = ref.watch(decksProvider(query));
    final quizzes = ref.watch(quizzesProvider(query));
    final questions = ref.watch(questionListProvider(query));

    final loading = decks.isLoading || quizzes.isLoading || questions.isLoading;
    final failed = [decks, quizzes, questions].where((v) => v.hasError && !v.hasValue).firstOrNull;
    final deckList = decks.value ?? const [];
    final quizList = quizzes.value ?? const [];
    final questionCount = questions.value?.totalCount ?? 0;
    final text = Theme.of(context).textTheme;

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
      body = const Center(child: CircularProgressIndicator());
    } else if (deckList.isEmpty && quizList.isEmpty && questionCount == 0) {
      body = const EmptyState('لا يوجد محتوى في هذا الدرس بعد', icon: Icons.article_outlined);
    } else {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (deckList.isNotEmpty) ...[
                Text('البطاقات التعليمية', style: text.titleMedium),
                const SizedBox(height: 8),
                for (final d in deckList) DeckTile(deck: d),
                const SizedBox(height: 16),
              ],
              if (quizList.isNotEmpty) ...[
                Text('الاختبارات', style: text.titleMedium),
                const SizedBox(height: 8),
                for (final q in quizList) QuizTile(quiz: q),
                const SizedBox(height: 16),
              ],
              if (questionCount > 0) ...[
                Text('الأسئلة', style: text.titleMedium),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.quiz_outlined),
                    title: const Text('أسئلة الدرس'),
                    subtitle: Text(questionCountLabel(questionCount)),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go('${Routes.subjects}/$subjectId/questions?lessonId=$lessonId'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
