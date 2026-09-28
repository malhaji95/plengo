import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/widgets/async_view.dart';
import '../../core/api/generated/export.dart';
import '../access/access_banner.dart';
import '../bookmarks/bookmark_button.dart';
import 'decks_screen.dart';
import 'flashcard_providers.dart';

/// Deck details with its two modes: تصفح (Browse) and مراجعة (Study) (spec §13.2).
class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider(deckId));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.value?.titleAr ?? ''),
        actions: [BookmarkButton(type: BookmarkItemType.deck, id: deckId)],
      ),
      body: AsyncView(
        value: deck,
        onRetry: () => ref.invalidate(deckProvider(deckId)),
        data: (d) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(d.titleAr, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cardCountLabel(d.cardCount), style: text.bodyMedium),
                if (d.description != null) ...[const SizedBox(height: 8), Text(d.description!)],
                const SizedBox(height: 24),
                if (d.locked)
                  const LockedNotice()
                else ...[
                  FilledButton.icon(
                    onPressed: () => context.push('${Routes.decks}/$deckId/study'),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text('مراجعة'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('${Routes.decks}/$deckId/browse'),
                    icon: const Icon(Icons.flip_outlined),
                    label: const Text('تصفح'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
