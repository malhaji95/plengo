import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/srs/scheduler.dart';
import '../../shared/widgets/async_view.dart';
import 'card_face.dart';
import 'flashcard_providers.dart';

/// Study mode (مراجعة): spaced repetition with three buttons and undo (spec §13.3). Keyboard on web:
/// Space flips, 1/2/3 rate Again/Good/Easy, Z undoes the last rating.
class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key, required this.source, required this.title});

  final StudySource source;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(studyControllerProvider(source));
    final ctl = ref.read(studyControllerProvider(source).notifier);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: study,
        onRetry: () => ref.invalidate(studyControllerProvider(source)),
        data: (s) {
          final card = s.current;
          final q = s.queue;
          final previews = s.flipped ? ctl.previews() : null;
          if (card != null) {
            final upcoming = q.next == null ? const <String>[] : s.order.where((id) => id != q.next).take(3);
            ref.read(cardImagePrefetchProvider)(context, [
              for (final id in upcoming) ...[s.cards[id]!.front, s.cards[id]!.back],
            ]);
          }
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.space): ctl.flip,
              const SingleActivator(LogicalKeyboardKey.digit1): () => ctl.rate(Rating.again),
              const SingleActivator(LogicalKeyboardKey.digit2): () => ctl.rate(Rating.good),
              const SingleActivator(LogicalKeyboardKey.digit3): () => ctl.rate(Rating.easy),
              const SingleActivator(LogicalKeyboardKey.keyZ): ctl.undo,
            },
            child: Focus(
              autofocus: true,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'جديدة ${q.newCount} · تعلّم ${q.learningCount} · مراجعة ${q.reviewCount}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      if (card == null)
                        _Done(nextDueAt: q.nextDueAt)
                      else ...[
                        FlashcardView(card: card, flipped: s.flipped, onTap: ctl.flip),
                        const SizedBox(height: 16),
                        if (previews == null)
                          FilledButton(onPressed: ctl.flip, child: const Text('اقلب البطاقة'))
                        else
                          Row(
                            children: [
                              for (final (rating, label) in [
                                (Rating.again, 'مرة أخرى'),
                                (Rating.good, 'جيد'),
                                (Rating.easy, 'سهل'),
                              ]) ...[
                                Expanded(
                                  child: _RatingButton(
                                    label: label,
                                    interval: previews[rating]!.label,
                                    color: switch (rating) {
                                      Rating.again => Theme.of(context).colorScheme.error,
                                      Rating.good => Theme.of(context).colorScheme.primary,
                                      Rating.easy => Colors.green.shade700,
                                    },
                                    onPressed: () => ctl.rate(rating),
                                  ),
                                ),
                                if (rating != Rating.easy) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                      ],
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: s.undoCount > 0 ? ctl.undo : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('تراجع'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({required this.label, required this.interval, required this.color, required this.onPressed});

  final String label;
  final String interval;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12)),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(interval, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.nextDueAt});

  final int? nextDueAt;

  @override
  Widget build(BuildContext context) {
    final next = nextDueAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(nextDueAt!, isUtc: true).add(const Duration(hours: 3));
    String two(int v) => v.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('أنهيت مراجعة اليوم 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text('البطاقة التالية: ${next.year}/${next.month}/${next.day} ${two(next.hour)}:${two(next.minute)}'),
          ],
        ],
      ),
    );
  }
}
