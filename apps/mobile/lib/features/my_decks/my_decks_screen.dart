import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/content/my_decks_store.dart';
import '../../core/db/app_database.dart';
import '../../shared/util/uuid.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/decks_screen.dart';
import 'my_decks_providers.dart';
import '../../shared/widgets/responsive.dart';

/// Deck colours the student can pick (stored as #RRGGBB).
const deckColors = ['#1E88E5', '#43A047', '#F4511E', '#8E24AA', '#FDD835', '#546E7A'];

Color? deckColor(String? hex) => hex == null ? null : Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// "بطاقاتي": the student's private decks (spec §13.9). Works offline; changes sync in the background.
class MyDecksScreen extends ConsumerStatefulWidget {
  const MyDecksScreen({super.key});

  @override
  ConsumerState<MyDecksScreen> createState() => _MyDecksScreenState();
}

class _MyDecksScreenState extends ConsumerState<MyDecksScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(myDecksSyncProvider).syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(myDecksProvider);
    listenForSyncNotices(context, ref);
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقاتي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createDeck(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('مجموعة جديدة'),
      ),
      body: AsyncView(
        value: decks,
        onRetry: () => ref.invalidate(myDecksProvider),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(myDecksSyncProvider).syncNow(),
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      'أنشئ مجموعتك الأولى وأضف إليها بطاقاتك الخاصة',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                  ],
                )
              : ResponsiveList(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: deckColor(d.deck.color) ?? Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.style_outlined, color: Colors.white),
                        ),
                        title: Text(d.deck.name),
                        subtitle: Text(cardCountLabel(d.cardCount)),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.go('${Routes.myDecks}/${d.deck.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Shows the server's refusals from the last sync once.
void listenForSyncNotices(BuildContext context, WidgetRef ref) {
  ref.listen(myDecksSyncNoticeProvider, (_, rejected) {
    if (rejected.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rejectionMessage(rejected.first))));
    ref.read(myDecksSyncNoticeProvider.notifier).clear();
  });
}

/// Creates a deck (after the quota check) and returns its id.
Future<String?> createDeck(BuildContext context, WidgetRef ref) async {
  final store = ref.read(myDecksStoreProvider);
  if (await store.liveDeckCount() >= userDeckQuota) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت إلى الحد الأقصى: 50 مجموعة')));
    }
    return null;
  }
  if (!context.mounted) return null;
  final result = await showDialog<({String name, String? color})>(context: context, builder: (_) => const DeckDialog());
  if (result == null) return null;
  final id = uuidV4();
  await store.saveDeck(id: id, name: result.name, color: result.color);
  ref.read(myDecksSyncProvider).schedule();
  return id;
}

/// Name and colour of a deck (new or renamed).
class DeckDialog extends StatefulWidget {
  const DeckDialog({super.key, this.initial});

  final LocalDeckRow? initial;

  @override
  State<DeckDialog> createState() => _DeckDialogState();
}

class _DeckDialogState extends State<DeckDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late String? _color = widget.initial?.color ?? deckColors.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _name.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.initial == null ? 'مجموعة جديدة' : 'تعديل المجموعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('deck-name'),
            controller: _name,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'اسم المجموعة'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final c in deckColors)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: deckColor(c),
                    child: _color == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, (name: _name.text.trim(), color: _color)) : null,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
