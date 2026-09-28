import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import '../my_decks/my_decks_providers.dart';
import 'decks_screen.dart';
import 'flashcard_providers.dart';

final dueCardsProvider = FutureProvider.autoDispose<DueCards>((ref) async {
  await ref.read(srsSyncProvider).syncNow();
  return ref.watch(flashcardRepositoryProvider).due();
});

/// The Review tab (المراجعة): every due card across accessible decks, optionally one subject
/// ("كل البطاقات المستحقة", spec §13.2), plus the mistake bank and statistics (§16).
class ReviewTab extends ConsumerStatefulWidget {
  const ReviewTab({super.key});

  @override
  ConsumerState<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends ConsumerState<ReviewTab> {
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final due = ref.watch(dueCardsProvider);
    // The links work offline (student decks, §13.9); only the due list needs the server.
    return Scaffold(
      appBar: AppBar(title: const Text('المراجعة')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dueCardsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _LearningLinks(),
            const SizedBox(height: 16),
            AsyncView(
              value: due,
              onRetry: () => ref.invalidate(dueCardsProvider),
              data: (d) {
                final subjects = <String, String>{for (final c in d.cards) c.subjectId: c.subjectNameAr};
                // The student's own cards count in "كل المواد" (their decks have no required subject).
                final count =
                    d.cards.where((c) => _subjectId == null || c.subjectId == _subjectId).length +
                    (_subjectId == null ? d.userCards.length : 0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subjects.length > 1)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('كل المواد'),
                            selected: _subjectId == null,
                            onSelected: (_) => setState(() => _subjectId = null),
                          ),
                          for (final MapEntry(key: id, value: name) in subjects.entries)
                            ChoiceChip(
                              label: Text(name),
                              selected: _subjectId == id,
                              onSelected: (_) => setState(() => _subjectId = id),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    if (count == 0)
                      const EmptyState('لا توجد بطاقات مستحقة الآن 🎉', icon: Icons.check_circle_outline)
                    else ...[
                      Text(
                        'كل البطاقات المستحقة: ${cardCountLabel(count)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          await context.push(
                            Uri(
                              path: Routes.dueStudy,
                              queryParameters: _subjectId == null ? null : {'subjectId': _subjectId},
                            ).toString(),
                          );
                          ref.invalidate(dueCardsProvider);
                        },
                        icon: const Icon(Icons.psychology_outlined),
                        label: const Text('ابدأ المراجعة'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Mistake bank and statistics live under the Review tab.
class _LearningLinks extends ConsumerWidget {
  const _LearningLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      if (ref.watch(studentDecksEnabledProvider))
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: const Text('بطاقاتي'),
            subtitle: const Text('مجموعاتك الخاصة من البطاقات'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.go(Routes.myDecks),
          ),
        ),
      Row(
        children: [
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.replay_circle_filled_outlined),
                title: const Text('مراجعة الأخطاء'),
                onTap: () => context.go(Routes.mistakes),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('إحصائياتي'),
                onTap: () => context.go(Routes.stats),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
