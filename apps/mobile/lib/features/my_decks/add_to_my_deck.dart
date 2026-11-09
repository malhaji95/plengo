import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/my_decks_store.dart';
import '../../shared/ui/ui.dart';
import '../../shared/util/uuid.dart';
import 'my_decks_providers.dart';
import 'my_decks_screen.dart';

/// "أضف إلى بطاقاتي" (spec §13.9): pick one of the student's decks (or create one) and add a
/// reference to this official card. It shows the official images while the card stays accessible.
/// Resolves to whether the card was added.
Future<bool> addToMyDeck(BuildContext context, WidgetRef ref, StudentCard official) async {
  final store = ref.read(myDecksStoreProvider);
  if (await store.liveCardCount() >= userCardQuota) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت إلى الحد الأقصى: 5000 بطاقة')));
    }
    return false;
  }
  final decks = await store.decks();
  if (!context.mounted) return false;
  const create = '__new__';
  final choice = await showPlengoSheet<String>(
    context: context,
    title: 'أضف إلى بطاقاتي',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final d in decks)
          ListRow(
            flat: true,
            title: d.deck.name,
            leading: DeckColorDot(hue: deckHue(d.deck.color, d.deck.id)),
            onTap: () => Navigator.pop(context, d.deck.id),
          ),
        ListRow(
          flat: true,
          showDivider: false,
          title: 'مجموعة جديدة',
          icon: Icons.add_rounded,
          hue: PlengoColors.pink,
          onTap: () => Navigator.pop(context, create),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return false;
  final deckId = choice == create ? await createDeck(context, ref) : choice;
  if (deckId == null) return false;
  await store.addOfficialRef(id: uuidV4(), deckId: deckId, official: official);
  ref.read(myDecksSyncProvider).schedule();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أُضيفت البطاقة إلى مجموعتك')));
  }
  return true;
}
