import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/my_decks_store.dart';
import '../../shared/util/uuid.dart';
import 'my_decks_providers.dart';
import 'my_decks_screen.dart';

/// "أضف إلى بطاقاتي" (spec §13.9): pick one of the student's decks (or create one) and add a
/// reference to this official card. It shows the official images while the card stays accessible.
Future<void> addToMyDeck(BuildContext context, WidgetRef ref, StudentCard official) async {
  final store = ref.read(myDecksStoreProvider);
  if (await store.liveCardCount() >= userCardQuota) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت إلى الحد الأقصى: 5000 بطاقة')));
    }
    return;
  }
  final decks = await store.decks();
  if (!context.mounted) return;
  const create = '__new__';
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('أضف إلى بطاقاتي', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final d in decks)
            ListTile(
              leading: CircleAvatar(radius: 12, backgroundColor: deckColor(d.deck.color)),
              title: Text(d.deck.name),
              onTap: () => Navigator.pop(context, d.deck.id),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('مجموعة جديدة'),
            onTap: () => Navigator.pop(context, create),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final deckId = choice == create ? await createDeck(context, ref) : choice;
  if (deckId == null) return;
  await store.addOfficialRef(id: uuidV4(), deckId: deckId, official: official);
  ref.read(myDecksSyncProvider).schedule();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أُضيفت البطاقة إلى مجموعتك')));
  }
}
