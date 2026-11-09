import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../bookmarks/bookmark_button.dart';
import '../flashcards/card_face.dart';
import '../flashcards/decks_screen.dart';
import '../flashcards/flashcard_ui.dart';
import 'my_decks_providers.dart';
import 'my_decks_screen.dart';

/// One of the student's decks: study, browse, and manage its cards (spec §13.9). Redesign: V-MyDecks.
class MyDeckScreen extends ConsumerWidget {
  const MyDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(myDeckProvider(deckId));
    final cards = ref.watch(myDeckCardsProvider(deckId));
    listenForSyncNotices(context, ref);
    final d = deck.value;
    final s = context.surface;
    return Scaffold(
      appBar: plengoAppBar(
        context,
        title: d?.name ?? '',
        actions: [
          if (d != null)
            PopupMenuButton<String>(
              tooltip: 'خيارات المجموعة',
              icon: const Icon(Icons.more_vert_rounded),
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
              backgroundColor: s.action,
              foregroundColor: s.onAction,
              onPressed: () => context.push('${Routes.myDecks}/$deckId/cards/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('بطاقة جديدة'),
            ),
      body: AsyncView(
        value: cards,
        onRetry: () => ref.invalidate(myDeckCardsProvider(deckId)),
        data: (list) {
          if (d == null && !deck.isLoading) return const EmptyState('لم تعد هذه المجموعة موجودة');
          final studyable = list.where((c) => !c.locked).length;
          final hue = d == null ? PlengoColors.pink : deckHue(d.color, d.id);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 96),
                children: [
                  Row(
                    children: [
                      SubjectIconTile(icon: Icons.collections_bookmark_rounded, hue: hue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cardCountLabel(list.length), style: PlengoType.rowTitle.copyWith(color: s.ink)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 14,
                        child: PlengoButton(
                          label: 'مراجعة',
                          icon: Icons.psychology_outlined,
                          onPressed: studyable == 0 ? null : () => context.push('${Routes.myDeckStudy}/$deckId/study'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 10,
                        child: PlengoButton(
                          label: 'تصفح',
                          variant: PlengoButtonVariant.secondary,
                          onPressed: studyable == 0 ? null : () => context.push('${Routes.myDeckStudy}/$deckId/browse'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    const EmptyState('أضف بطاقتك الأولى', icon: Icons.note_add_outlined)
                  else
                    const SectionHeader('البطاقات', top: 0),
                  for (final c in list) ...[
                    _CardTile(card: c, deckId: deckId),
                    const SizedBox(height: PlengoSpace.listGap),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, LocalDeckRow d) async {
    final result = await showDeckForm(context, initial: d);
    if (result == null) return;
    await ref
        .read(myDecksStoreProvider)
        .saveDeck(id: d.id, name: result.name, color: result.color, subjectId: d.subjectId);
    ref.read(myDecksSyncProvider).schedule();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, LocalDeckRow d) async {
    final ok = await showConfirmSheet(
      context,
      title: 'حذف المجموعة؟',
      message: 'ستُحذف المجموعة وكل بطاقاتها.',
      icon: Icons.delete_outline_rounded,
      hue: PlengoColors.red,
      primaryLabel: 'حذف',
      primaryVariant: PlengoButtonVariant.danger,
      secondaryLabel: 'إلغاء',
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
    final s = context.surface;
    final view = StudyCard.own(card);
    final official = card.officialFlashcardId != null;
    final title = official ? 'بطاقة من المحتوى الرسمي' : (view.front.text ?? 'صورة');
    final subtitle = card.locked ? 'غير متاحة على حسابك حالياً' : (view.back.text ?? '');
    final image = view.front.localImage != null
        ? SizedBox.square(dimension: 44, child: ref.watch(localImageBuilderProvider)(context, view.front.localImage!))
        : view.front.image != null && !card.locked
        ? CachedNetworkImage(
            imageUrl: view.front.image!.thumbUrl,
            cacheKey: '${view.front.image!.cacheKey}:thumb',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const Icon(Icons.image_outlined),
          )
        : null;
    return ActionRow(
      title: title,
      caption: subtitle.isEmpty ? null : subtitle,
      leading: image != null
          ? ClipRRect(borderRadius: BorderRadius.circular(PlengoRadius.iconTile), child: image)
          : SubjectIconTile(
              icon: card.locked ? Icons.lock_rounded : Icons.crop_portrait_rounded,
              hue: card.locked ? PlengoColors.red : PlengoColors.pink,
              soft: true,
            ),
      onTap: official ? null : () => context.push('${Routes.myDecks}/$deckId/cards/${card.id}'),
      trailing: [
        BookmarkButton(type: BookmarkItemType.userCard, id: card.id),
        IconButton(
          tooltip: 'حذف البطاقة',
          color: s.mute,
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () async {
            await ref.read(myDecksStoreProvider).deleteCard(card.id);
            ref.read(myDecksSyncProvider).schedule();
          },
        ),
      ],
    );
  }
}
