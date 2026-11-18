import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/srs/srs_key.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/browse_screen.dart';
import '../flashcards/card_face.dart';
import '../flashcards/flashcard_ui.dart';
import '../flashcards/hard_cards.dart';
import '../my_decks/my_decks_providers.dart';
import '../questions/questions_screen.dart';
import '../shell/app_drawer.dart';
import 'bookmark_button.dart';
import 'bookmark_providers.dart';

const _filters = <BookmarkItemType?, String>{
  null: 'الكل',
  BookmarkItemType.question: 'الأسئلة',
  BookmarkItemType.deck: 'المجموعات',
  BookmarkItemType.flashcard: 'البطاقات',
  BookmarkItemType.userCard: 'بطاقاتي',
};

/// `?filter=` values of the saved tab and the type each one selects.
const savedFilters = <String, BookmarkItemType>{
  'questions': BookmarkItemType.question,
  'decks': BookmarkItemType.deck,
  'cards': BookmarkItemType.flashcard,
  'my-cards': BookmarkItemType.userCard,
};

/// The Saved tab (المحفوظات, spec §17). Items the student can no longer open show as locked.
/// Redesign: V-Saved. [filter] (`?filter=cards`, see [savedFilters]) picks the first type pill and
/// [subjectId] (`?subjectId=`) keeps one subject's items (v3: «مراجعة البطاقات الصعبة» and «راجع
/// أخطاءك»). Cards the student finds hard ([hardCardsProvider]) carry «صعبة» and come first. Starred
/// cards (v3 §8) are filed by their deck: one row per subject › unit › deck with the number of stars,
/// which opens those cards in Browse ([starGroups]); hard cards and cards without a deck stay single rows.
class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key, this.filter, this.subjectId});

  final String? filter;
  final String? subjectId;

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  late BookmarkItemType? _type = savedFilters[widget.filter];
  late String? _subjectId = widget.subjectId;

  @override
  void didUpdateWidget(SavedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new link into the tab (e.g. from موادي) replaces the filters.
    if (oldWidget.filter != widget.filter || oldWidget.subjectId != widget.subjectId) {
      _type = savedFilters[widget.filter];
      _subjectId = widget.subjectId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bookmarksProvider);
    final hard = ref.watch(hardCardsProvider).value ?? const <String>{};
    final menu = DrawerMenuButton.leadingOf(context);
    // Toggling elsewhere refreshes the list.
    ref.listen(bookmarkKeysProvider, (_, _) => ref.invalidate(bookmarksProvider));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: menu,
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: menu == null ? PlengoSpace.screen : null,
        title: const Text('المحفوظات'),
      ),
      body: AsyncView(
        value: list,
        onRetry: () => ref.invalidate(bookmarksProvider),
        data: (l) {
          bool isHard(Bookmark b) => b.itemType == BookmarkItemType.flashcard && hard.contains(b.itemId);
          final items = l.items
              .where((b) => (_type == null || b.itemType == _type) && (_subjectId == null || b.subjectId == _subjectId))
              .toList();
          // Starred cards are filed under their deck; hard ones also stay as single rows, first.
          final groups = starGroups(items);
          final grouped = {for (final g in groups) ...g.cards.map((b) => b.id)};
          final singles = items.where((b) => isHard(b) || !grouped.contains(b.id));
          final ordered = [...singles.where(isHard), ...singles.where((b) => !isHard(b))];
          final subjectName = _subjectId == null
              ? null
              : l.items.where((b) => b.subjectId == _subjectId).firstOrNull?.subjectNameAr;
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
                    if (_subjectId != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 0),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            PlengoChip(
                              label: subjectName ?? 'مادة واحدة',
                              hue: PlengoColors.blue,
                              icon: Icons.filter_alt_outlined,
                            ),
                            TextButton(
                              key: const Key('saved.allSubjects'),
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                              onPressed: () => setState(() => _subjectId = null),
                              child: const Text('كل المواد'),
                            ),
                          ],
                        ),
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
                    if (groups.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
                        child: SectionHeader('البطاقات المميّزة بنجمة', top: 0),
                      ),
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            PlengoSpace.screen,
                            0,
                            PlengoSpace.screen,
                            PlengoSpace.listGap,
                          ),
                          child: _StarGroupTile(group: g),
                        ),
                      if (ordered.isNotEmpty) const SizedBox(height: 10),
                    ],
                    for (final b in ordered)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          PlengoSpace.screen,
                          0,
                          PlengoSpace.screen,
                          PlengoSpace.listGap,
                        ),
                        child: _BookmarkTile(bookmark: b, hard: isHard(b)),
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
  const _BookmarkTile({required this.bookmark, this.hard = false});

  final Bookmark bookmark;

  /// One of the cards the student finds hard: marked «صعبة».
  final bool hard;

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
        if (hard)
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 4),
            child: PlengoChip(label: 'صعبة', hue: PlengoColors.orange, icon: Icons.local_fire_department_rounded),
          ),
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

/// Starred cards of one deck (v3 §8), filed subject › unit › deck.
class StarGroup {
  const StarGroup({required this.key, required this.path, required this.group, required this.cards});

  final String key;

  /// «المادة › الوحدة › المجموعة», the parts the server knows.
  final List<String> path;
  final BookmarkGroup group;
  final List<Bookmark> cards;

  String get title => group.deckTitle ?? path.lastOrNull ?? 'بطاقات محفوظة';
}

/// The starred cards among [items] that carry their deck ([Bookmark.group]), one [StarGroup] per
/// deck, ordered by subject, unit and deck name.
List<StarGroup> starGroups(Iterable<Bookmark> items) {
  final byKey = <String, List<Bookmark>>{};
  for (final b in items) {
    final g = b.group;
    final card = b.itemType == BookmarkItemType.flashcard || b.itemType == BookmarkItemType.userCard;
    if (!card || g == null || g.deckId == null) continue;
    byKey.putIfAbsent('${g.ownDeck ? 'own' : 'deck'}:${g.deckId}', () => []).add(b);
  }
  final groups = [
    for (final MapEntry(:key, :value) in byKey.entries)
      StarGroup(
        key: key,
        group: value.first.group!,
        cards: value,
        path: [?value.first.group!.subjectNameAr, ?value.first.group!.unitTitleAr, ?value.first.group!.deckTitle],
      ),
  ];
  groups.sort((a, b) => a.path.join('\u0000').compareTo(b.path.join('\u0000')));
  return groups;
}

/// «اللغة الإنكليزية › Unit 1 › Vocabulary» with «50 ★»; a tap browses those cards.
class _StarGroupTile extends StatelessWidget {
  const _StarGroupTile({required this.group});

  final StarGroup group;

  @override
  Widget build(BuildContext context) {
    final path = group.path.map(isolateLtr).join(' › ');
    final count = group.cards.length;
    final hue = group.group.subjectId == null ? PlengoColors.yellow : subjectHue(group.group.subjectId!);
    return ActionRow(
      key: Key('saved.group.${group.key}'),
      title: path.isEmpty ? group.title : path,
      caption: group.group.ownDeck ? 'من بطاقاتي' : 'بطاقات بلينغو',
      leading: SubjectIconTile(icon: Icons.star_rounded, hue: hue, soft: true),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StarredCardsScreen(group: group))),
      trailing: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
          child: PlengoChip(label: '$count ★', hue: PlengoColors.yellow, semanticsLabel: '$count بطاقة بنجمة'),
        ),
      ],
    );
  }
}

/// The starred cards of one deck in Browse (their ★ stays on each card).
class StarredCardsScreen extends ConsumerWidget {
  const StarredCardsScreen({super.key, required this.group});

  final StarGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = group.group;
    final template = g.ownDeck && g.deckId != null ? ref.watch(myDeckProvider(g.deckId!)).value?.templateKey : null;
    final cards = [
      for (final b in group.cards)
        if (b.available && !b.locked)
          if (b.card case final c?)
            StudyCard.official(c)
          else if (b.userCard case final u?)
            StudyCard(
              key: SrsKey.userCard(u.id),
              officialId: u.officialFlashcardId,
              templateKey: u.officialFlashcardId == null ? template : null,
              front: CardFaceView(text: u.front.text, image: u.front.image),
              back: CardFaceView(text: u.back.text, image: u.back.image),
            ),
    ];
    return CardBrowser(title: group.title, cards: cards);
  }
}
