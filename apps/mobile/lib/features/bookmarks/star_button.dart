import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/srs/srs_key.dart';
import '../../shared/ui/ui.dart';
import '../my_decks/my_decks_providers.dart';
import 'bookmark_providers.dart';

/// The bookmark behind a card's ★ (v3 §8): an official card, or one of the student's own cards.
({BookmarkItemType type, String id}) starTarget(StudyCard card) => SrsKey.isUserCard(card.key)
    ? (type: BookmarkItemType.userCard, id: SrsKey.idOf(card.key))
    : (type: BookmarkItemType.flashcard, id: card.key);

/// Whether [card] is starred.
bool cardStarred(WidgetRef ref, StudyCard card) {
  final t = starTarget(card);
  return ref.watch(bookmarkKeysProvider).value?.contains(bookmarkKey(t.type, t.id)) ?? false;
}

/// Stars or unstars [card]. A card of the student's own is synced first so the server knows it.
Future<void> toggleStar(BuildContext context, WidgetRef ref, StudyCard card) async {
  final t = starTarget(card);
  try {
    if (t.type == BookmarkItemType.userCard) await ref.read(myDecksSyncProvider).syncNow();
    await ref.read(bookmarkKeysProvider.notifier).toggle(t.type, t.id);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الحفظ، حاول مرة أخرى')));
    }
  }
}

/// The ★ on every card in Browse and Study: a yellow star when the card is saved (filed under its
/// deck in المحفوظات), an outline otherwise.
class StarButton extends ConsumerWidget {
  const StarButton({super.key, required this.card});

  final StudyCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = cardStarred(ref, card);
    final s = context.surface;
    return Semantics(
      toggled: starred,
      child: PlengoIconButton(
        key: const Key('card.star'),
        icon: starred ? Icons.star_rounded : Icons.star_outline_rounded,
        tooltip: starred ? 'إزالة النجمة' : 'نجمة: احفظ البطاقة',
        color: starred ? PlengoColors.yellow.shadow : s.ink,
        onPressed: () => toggleStar(context, ref, card),
      ),
    );
  }
}
