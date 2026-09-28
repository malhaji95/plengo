import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/db/app_database.dart';
import '../../shared/widgets/async_view.dart';
import '../bookmarks/bookmark_button.dart';
import '../flashcards/card_face.dart';
import '../flashcards/decks_screen.dart';
import 'my_decks_providers.dart';
import 'my_decks_screen.dart';

/// One of the student's decks: study, browse, and manage its cards (spec §13.9).
class MyDeckScreen extends ConsumerWidget {
  const MyDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(myDeckProvider(deckId));
    final cards = ref.watch(myDeckCardsProvider(deckId));
    listenForSyncNotices(context, ref);
    final d = deck.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.name ?? ''),
        actions: [
          if (d != null)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'rename' ? _rename(context, ref, d) : _delete(context, ref, d),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('تعديل المجموعة')),
                PopupMenuItem(value: 'delete', child: Text('حذف المجموعة')),
              ],
            ),
        ],
      ),
      floatingActionButton: d == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('${Routes.myDecks}/$deckId/cards/new'),
              icon: const Icon(Icons.add),
              label: const Text('بطاقة جديدة'),
            ),
      body: AsyncView(
        value: cards,
        onRetry: () => ref.invalidate(myDeckCardsProvider(deckId)),
        data: (list) {
          if (d == null && !deck.isLoading) return const EmptyState('لم تعد هذه المجموعة موجودة');
          final studyable = list.where((c) => !c.locked).length;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(cardCountLabel(list.length), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: studyable == 0 ? null : () => context.push('${Routes.myDeckStudy}/$deckId/study'),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text('مراجعة'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: studyable == 0 ? null : () => context.push('${Routes.myDeckStudy}/$deckId/browse'),
                    icon: const Icon(Icons.flip_outlined),
                    label: const Text('تصفح'),
                  ),
                  const SizedBox(height: 24),
                  if (list.isEmpty) const EmptyState('أضف بطاقتك الأولى', icon: Icons.note_add_outlined),
                  for (final c in list) _CardTile(card: c, deckId: deckId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, LocalDeckRow d) async {
    final result = await showDialog<({String name, String? color})>(
      context: context,
      builder: (_) => DeckDialog(initial: d),
    );
    if (result == null) return;
    await ref
        .read(myDecksStoreProvider)
        .saveDeck(id: d.id, name: result.name, color: result.color, subjectId: d.subjectId);
    ref.read(myDecksSyncProvider).schedule();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, LocalDeckRow d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المجموعة؟'),
        content: const Text('ستُحذف المجموعة وكل بطاقاتها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(myDecksStoreProvider).deleteDeck(d.id);
    ref.read(myDecksSyncProvider).schedule();
    if (context.mounted) context.go(Routes.myDecks);
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card, required this.deckId});

  final LocalCardRow card;
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = StudyCard.own(card);
    final official = card.officialFlashcardId != null;
    final title = official ? 'بطاقة من المحتوى الرسمي' : (view.front.text ?? 'صورة');
    final subtitle = card.locked ? 'غير متاحة على حسابك حالياً' : (view.back.text ?? '');
    final image = view.front.localImage != null
        ? SizedBox.square(dimension: 48, child: ref.watch(localImageBuilderProvider)(context, view.front.localImage!))
        : view.front.image != null && !card.locked
        ? CachedNetworkImage(
            imageUrl: view.front.image!.thumbUrl,
            cacheKey: '${view.front.image!.cacheKey}:thumb',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const Icon(Icons.image_outlined),
          )
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: image ?? Icon(card.locked ? Icons.lock_outline : Icons.crop_portrait),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: official ? null : () => context.push('${Routes.myDecks}/$deckId/cards/${card.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BookmarkButton(type: BookmarkItemType.userCard, id: card.id),
            IconButton(
              tooltip: 'حذف البطاقة',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(myDecksStoreProvider).deleteCard(card.id);
                ref.read(myDecksSyncProvider).schedule();
              },
            ),
          ],
        ),
      ),
    );
  }
}
