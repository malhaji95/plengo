import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import 'catalog_providers.dart';

/// A subject's outline: optional units with their lessons, then lessons directly under the subject.
/// Questions, decks and quizzes appear here from Phase 5 on.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: Text(outline.value?.subject.nameAr ?? '')),
      body: AsyncView(
        value: outline,
        onRetry: () => ref.invalidate(subjectOutlineProvider(subjectId)),
        data: (o) => _OutlineView(outline: o),
      ),
    );
  }
}

class _OutlineView extends StatelessWidget {
  const _OutlineView({required this.outline});

  final SubjectOutline outline;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final empty = outline.units.isEmpty && outline.lessons.isEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (outline.subject.description != null) ...[
              Text(outline.subject.description!, style: text.bodyMedium),
              const SizedBox(height: 16),
            ],
            if (empty) const EmptyState('محتوى هذه المادة قيد الإعداد', icon: Icons.hourglass_empty),
            for (final (i, unit) in outline.units.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  key: PageStorageKey(unit.id),
                  initiallyExpanded: i == 0,
                  leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: text.labelMedium)),
                  title: Text(unit.titleAr, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(lessonCountLabel(unit.lessons.length)),
                  children: [
                    if (unit.lessons.isEmpty)
                      const ListTile(title: Text('لا توجد دروس في هذه الوحدة بعد')),
                    for (final lesson in unit.lessons) _LessonTile(lesson: lesson),
                  ],
                ),
              ),
            if (outline.lessons.isNotEmpty) ...[
              if (outline.units.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('دروس عامة', style: text.titleSmall),
                const SizedBox(height: 8),
              ],
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [for (final lesson in outline.lessons) _LessonTile(lesson: lesson)]),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.article_outlined),
      title: Text(lesson.titleAr),
    );
  }
}

/// Arabic count agreement: درس واحد، درسان، 3–10 دروس، 11+ درساً.
String lessonCountLabel(int n) => switch (n) {
      0 => 'لا دروس بعد',
      1 => 'درس واحد',
      2 => 'درسان',
      >= 3 && <= 10 => '$n دروس',
      _ => '$n درساً',
    };
