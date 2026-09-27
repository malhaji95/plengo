import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/async_view.dart';
import 'card_face.dart';
import 'flashcard_providers.dart';

/// Browse mode (تصفح): flip, السابق / التالي, no scheduling (spec §13.2). Keyboard on web: Space
/// flips; the arrow pointing in the reading direction (left in Arabic) goes to the next card.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  int _index = 0;
  bool _flipped = false;

  void _go(int delta, int count) {
    final next = (_index + delta).clamp(0, count - 1);
    if (next != _index) setState(() => (_index = next, _flipped = false));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(deckCardsProvider(widget.deckId));
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(title: Text(data.value?.deck.titleAr ?? 'تصفح')),
      body: AsyncView(
        value: data,
        onRetry: () => ref.invalidate(deckCardsProvider(widget.deckId)),
        data: (d) {
          if (d.cards.isEmpty) return const EmptyState('لا بطاقات في هذه المجموعة');
          final card = d.cards[_index];
          final count = d.cards.length;
          ref.read(cardImagePrefetchProvider)(context, [
            for (final c in d.cards.skip(_index + 1).take(3)) ...[c.front, c.back],
          ]);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.space): () => setState(() => _flipped = !_flipped),
              SingleActivator(rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight): () => _go(1, count),
              SingleActivator(rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft): () => _go(-1, count),
            },
            child: Focus(
              autofocus: true,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('${_index + 1} / $count', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FlashcardView(card: card, flipped: _flipped, onTap: () => setState(() => _flipped = !_flipped)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _index > 0 ? () => _go(-1, count) : null,
                              child: const Text('السابق'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _flipped = !_flipped),
                              child: const Text('اقلب البطاقة'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _index < count - 1 ? () => _go(1, count) : null,
                              child: const Text('التالي'),
                            ),
                          ),
                        ],
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
