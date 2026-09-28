import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../shared/widgets/async_view.dart';
import '../my_decks/add_to_my_deck.dart';
import '../my_decks/my_decks_providers.dart';
import '../reports/report_sheet.dart';
import 'card_face.dart';
import 'flashcard_providers.dart';

/// Browse mode (تصفح) of an official deck: flip, السابق / التالي, no scheduling (spec §13.2). Each
/// card can be added to the student's decks (§13.9) or reported (§21).
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(deckCardsProvider(deckId));
    final decksOn = ref.watch(studentDecksEnabledProvider);
    final reportsOn = ref.watch(contentReportsEnabledProvider);
    return AsyncView(
      value: data,
      onRetry: () => ref.invalidate(deckCardsProvider(deckId)),
      frame: (child) => Scaffold(appBar: AppBar(), body: child),
      data: (d) {
        final byKey = {for (final c in d.cards) c.id: c};
        return CardBrowser(
          title: d.deck.titleAr,
          cards: [for (final c in d.cards) StudyCard.official(c)],
          actions: (card) => [
            if (decksOn)
              IconButton(
                tooltip: 'أضف إلى بطاقاتي',
                icon: const Icon(Icons.library_add_outlined),
                onPressed: () => addToMyDeck(context, ref, byKey[card.key]!),
              ),
            if (reportsOn)
              IconButton(
                tooltip: 'إبلاغ عن مشكلة',
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => showReportSheet(context, ref, ReportItemType.flashcard, card.key),
              ),
          ],
        );
      },
    );
  }
}

/// Browse mode of one of the student's decks (works offline).
class MyBrowseScreen extends ConsumerWidget {
  const MyBrowseScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(myDeckProvider(deckId)).value;
    final cards = ref.watch(myDeckCardsProvider(deckId));
    return AsyncView(
      value: cards,
      onRetry: () => ref.invalidate(myDeckCardsProvider(deckId)),
      frame: (child) => Scaffold(appBar: AppBar(), body: child),
      data: (rows) => CardBrowser(
        title: deck?.name ?? 'تصفح',
        cards: [
          for (final r in rows)
            if (!r.locked) StudyCard.own(r),
        ],
      ),
    );
  }
}

/// The browse UI. Keyboard on web: Space flips; the arrow pointing in the reading direction (left
/// in Arabic) goes to the next card.
class CardBrowser extends ConsumerStatefulWidget {
  const CardBrowser({super.key, required this.title, required this.cards, this.actions});

  final String title;
  final List<StudyCard> cards;
  final List<Widget> Function(StudyCard card)? actions;

  @override
  ConsumerState<CardBrowser> createState() => _CardBrowserState();
}

class _CardBrowserState extends ConsumerState<CardBrowser> {
  int _index = 0;
  bool _flipped = false;

  void _go(int delta, int count) {
    final next = (_index + delta).clamp(0, count - 1);
    if (next != _index) setState(() => (_index = next, _flipped = false));
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const EmptyState('لا بطاقات في هذه المجموعة'),
      );
    }
    _index = _index.clamp(0, cards.length - 1);
    final card = cards[_index];
    final count = cards.length;
    ref.read(cardImagePrefetchProvider)(context, [for (final c in cards.skip(_index + 1).take(3)) ...c.images]);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: widget.actions?.call(card)),
      body: CallbackShortcuts(
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
      ),
    );
  }
}
