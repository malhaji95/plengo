import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/srs/scheduler.dart';
import '../../app/theme.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/ui_kit.dart';
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
            ref.read(cardImagePrefetchProvider)(context, [for (final id in upcoming) ...s.cards[id]!.images]);
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
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Text(
                            'جديدة ${q.newCount} · تعلّم ${q.learningCount} · مراجعة ${q.reviewCount}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (card == null)
                        _Done(nextDueAt: q.nextDueAt)
                      else ...[
                        FlashcardView(card: card, flipped: s.flipped, onTap: ctl.flip),
                        const SizedBox(height: 12),
                        if (previews == null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'اضغط على البطاقة لعرض الإجابة',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: ctl.flip, child: const Text('اقلب البطاقة')),
                        ] else
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final (rating, label) in [
                                  (Rating.again, 'مرة أخرى'),
                                  (Rating.good, 'جيد'),
                                  (Rating.easy, 'سهل'),
                                ]) ...[
                                  Expanded(
                                    child: _RatingButton(
                                      rating: rating,
                                      label: label,
                                      interval: previews[rating]!.label,
                                      onPressed: () => ctl.rate(rating),
                                    ),
                                  ),
                                  if (rating != Rating.easy) const SizedBox(width: 10),
                                ],
                              ],
                            ),
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

/// One of the three ratings (§13.3): a tinted tile with an icon, the label and the predicted
/// interval, so the choice never relies on colour alone. Ink text on pale tints in both themes.
class _RatingButton extends StatelessWidget {
  const _RatingButton({required this.rating, required this.label, required this.interval, required this.onPressed});

  final Rating rating;
  final String label;
  final String interval;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (Color tint, Color mark, IconData icon) = switch (rating) {
      Rating.again => (BrandColors.tintRed, BrandColors.error, Icons.replay_rounded),
      Rating.good => (BrandColors.tintYellow, const Color(0xFF8A6100), Icons.thumb_up_alt_rounded),
      Rating.easy => (BrandColors.tintGreen, const Color(0xFF13852A), Icons.check_circle_rounded),
    };
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: mark, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: BrandColors.ink, fontWeight: FontWeight.w700),
              ),
              Text(interval, style: const TextStyle(color: BrandColors.ink, fontSize: 12)),
            ],
          ),
        ),
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
          const SpotIcon(Icons.emoji_events_rounded, tint: BrandColors.tintYellow, color: Color(0xFF8A6100), size: 120),
          const SizedBox(height: 16),
          Text('أنهيت مراجعة اليوم 🎉', style: Theme.of(context).textTheme.headlineSmall),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text('البطاقة التالية: ${next.year}/${next.month}/${next.day} ${two(next.hour)}:${two(next.minute)}'),
          ],
        ],
      ),
    );
  }
}
