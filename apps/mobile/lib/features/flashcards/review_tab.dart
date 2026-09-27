import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/async_view.dart';
import 'decks_screen.dart';
import 'flashcard_providers.dart';

final dueCardsProvider = FutureProvider.autoDispose<DueCards>((ref) async {
  await ref.read(srsSyncProvider).syncNow();
  return ref.watch(flashcardRepositoryProvider).due();
});

/// The Review tab (المراجعة): every due card across accessible decks, optionally one subject
/// ("كل البطاقات المستحقة", spec §13.2).
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
    return Scaffold(
      appBar: AppBar(title: const Text('المراجعة')),
      body: AsyncView(
        value: due,
        onRetry: () => ref.invalidate(dueCardsProvider),
        data: (d) {
          final subjects = <String, String>{for (final c in d.cards) c.subjectId: c.subjectNameAr};
          final count = d.cards.where((c) => _subjectId == null || c.subjectId == _subjectId).length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dueCardsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
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
            ),
          );
        },
      ),
    );
  }
}
