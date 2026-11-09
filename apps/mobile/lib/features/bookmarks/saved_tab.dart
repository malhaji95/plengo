import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/card_face.dart';
import '../flashcards/flashcard_ui.dart';
import '../questions/questions_screen.dart';
import 'bookmark_button.dart';
import 'bookmark_providers.dart';

const _filters = <BookmarkItemType?, String>{
  null: 'الكل',
  BookmarkItemType.question: 'الأسئلة',
  BookmarkItemType.deck: 'المجموعات',
  BookmarkItemType.flashcard: 'البطاقات',
  BookmarkItemType.userCard: 'بطاقاتي',
};

/// The Saved tab (المحفوظات, spec §17). Items the student can no longer open show as locked.
/// Redesign: V-Saved.
class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key});

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  BookmarkItemType? _type;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bookmarksProvider);
    // Toggling elsewhere refreshes the list.
    ref.listen(bookmarkKeysProvider, (_, _) => ref.invalidate(bookmarksProvider));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: PlengoSpace.screen,
        title: const Text('المحفوظات'),
      ),
      body: AsyncView(
        value: list,
        onRetry: () => ref.invalidate(bookmarksProvider),
        data: (l) {
          final items = l.items.where((b) => _type == null || b.itemType == _type).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(bookmarksProvider.future),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 28),
                  children: [
                    PillSelector<BookmarkItemType?>(
                      options: [for (final MapEntry(key: t, value: label) in _filters.entries) PlengoOption(t, label)],
                      selected: _type,
                      onSelected: (t) => setState(() => _type = t),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      PlengoEmptyState(
                        title: 'لا شيء محفوظ هنا بعد',
                        message: 'احفظ الأسئلة والبطاقات لتعود إليها هنا',
                        icon: Icons.bookmark_border_rounded,
                        hue: PlengoColors.pink,
                        actionLabel: 'تصفّح المواد',
                        onAction: () => context.go(Routes.subjects),
                      ),
                    for (final b in items)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          PlengoSpace.screen,
                          0,
                          PlengoSpace.screen,
                          PlengoSpace.listGap,
                        ),
                        child: _BookmarkTile(bookmark: b),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    final b = bookmark;
    final (IconData icon, String kind, PlengoHue hue) = switch (b.itemType) {
      BookmarkItemType.question => (Icons.quiz_rounded, 'سؤال', PlengoColors.blue),
      BookmarkItemType.deck => (Icons.style_rounded, 'مجموعة بطاقات', PlengoColors.orange),
      BookmarkItemType.userCard => (Icons.collections_bookmark_rounded, 'من بطاقاتي', PlengoColors.pink),
      _ => (Icons.crop_portrait_rounded, 'بطاقة', PlengoColors.green),
    };
    final title = !b.available
        ? 'لم يعد هذا العنصر متاحاً'
        : b.locked && b.itemType == BookmarkItemType.question
        ? 'سؤال مقفل'
        : b.titleAr ?? '';
    VoidCallback? onTap;
    if (b.available && !b.locked) {
      onTap = switch (b.itemType) {
        BookmarkItemType.question => () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PracticeScreen(title: 'سؤال محفوظ', questions: [b.question!]),
          ),
        ),
        BookmarkItemType.deck => () => context.go('${Routes.decks}/${b.itemId}'),
        BookmarkItemType.flashcard when b.card != null => () => _preview(context, StudyCard.official(b.card!)),
        BookmarkItemType.userCard when b.userCard != null => () => _preview(context, _ownCard(b.userCard!)),
        _ => null,
      };
    } else if (b.available && b.locked && b.itemType == BookmarkItemType.deck) {
      onTap = () => context.go('${Routes.decks}/${b.itemId}');
    }
    return ActionRow(
      title: isolateLtr(title),
      caption: [kind, if (b.subjectNameAr != null) b.subjectNameAr!].join(' · '),
      leading: SubjectIconTile(icon: icon, hue: hue, soft: true),
      onTap: onTap,
      trailing: [
        if (b.locked)
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 4),
            child: PlengoChip(label: 'مقفل', hue: PlengoColors.red, icon: Icons.lock_outline),
          ),
        BookmarkButton(type: b.itemType, id: b.itemId),
      ],
    );
  }
}

Future<void> _preview(BuildContext context, StudyCard card) => showDialog<void>(
  context: context,
  barrierColor: PlengoColors.scrim,
  builder: (_) => Dialog(
    backgroundColor: context.surface.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.hero)),
    child: _CardPreview(card: card),
  ),
);

class _CardPreview extends StatefulWidget {
  const _CardPreview({required this.card});

  final StudyCard card;

  @override
  State<_CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<_CardPreview> {
  bool _back = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PlengoIconButton(icon: Icons.close_rounded, tooltip: 'إغلاق', onPressed: () => Navigator.pop(context)),
        ),
        const SizedBox(height: 8),
        Center(
          child: FlashcardView(
            card: widget.card,
            flipped: _back,
            onTap: () => setState(() => _back = !_back),
            maxHeight: 420,
          ),
        ),
        const SizedBox(height: 12),
        PlengoButton(
          label: _back ? 'الوجه' : 'اقلب',
          variant: PlengoButtonVariant.secondary,
          onPressed: () => setState(() => _back = !_back),
        ),
      ],
    ),
  );
}

/// A saved card of the student's own, as the server sent it.
StudyCard _ownCard(UserCard c) => StudyCard(
  key: c.id,
  officialId: c.officialFlashcardId,
  front: CardFaceView(text: c.front.text, image: c.front.image),
  back: CardFaceView(text: c.back.text, image: c.back.image),
);
