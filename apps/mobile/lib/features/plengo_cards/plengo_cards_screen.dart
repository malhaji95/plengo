import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/decks_screen.dart' show cardCountLabel;
import '../flashcards/flashcard_providers.dart';
import '../flashcards/flashcard_ui.dart';
import '../shell/app_drawer.dart';
import 'place_header.dart';

/// The Plengo decks as products, grouped by subject (v3 §6), for the student's level.
final plengoDecksProvider = FutureProvider.autoDispose<PlengoDeckList>((ref) {
  final levelId = ref.watch(authControllerProvider.select((a) => a.value?.educationLevelId));
  return ref.watch(flashcardRepositoryProvider).plengoDecks(educationLevelId: levelId);
});

/// The groups shown for the pill [subjectId] (null = الكل), in the subjects' order; empty groups are
/// left out.
List<PlengoDeckGroup> visibleGroups(PlengoDeckList list, String? subjectId) {
  final groups = [
    for (final g in list.groups)
      if (g.decks.isNotEmpty && (subjectId == null || g.subjectId == subjectId)) g,
  ]..sort((a, b) => a.subjectSortOrder.compareTo(b.subjectSortOrder));
  return groups;
}

/// فلاش كاردز بلينغو (v3 §6) at [Routes.plengoCards]: the header art, a pill per subject («الكل»
/// first) and each subject's decks as product cards (the deck cover is the product box). A tap opens
/// the deck; a locked deck can browse its first cards. `?subjectId=` selects that subject's pill.
class PlengoCardsScreen extends ConsumerStatefulWidget {
  const PlengoCardsScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  ConsumerState<PlengoCardsScreen> createState() => _PlengoCardsScreenState();
}

class _PlengoCardsScreenState extends ConsumerState<PlengoCardsScreen> {
  late String? _subjectId = widget.subjectId;

  @override
  void didUpdateWidget(PlengoCardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId) _subjectId = widget.subjectId;
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(plengoDecksProvider);
    final menu = DrawerMenuButton.leadingOf(context);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop ? const PlengoBackButton() : menu,
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: menu == null && !canPop ? PlengoSpace.screen : null,
        title: const Text('فلاش كاردز بلينغو'),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: list,
          onRetry: () => ref.invalidate(plengoDecksProvider),
          data: (l) {
            final pills = visibleGroups(l, null);
            // A subject from the link that has no decks falls back to «الكل».
            final selected = pills.any((g) => g.subjectId == _subjectId) ? _subjectId : null;
            final groups = visibleGroups(l, selected);
            return RefreshIndicator(
              onRefresh: () => ref.refresh(plengoDecksProvider.future),
              child: ListView(
                padding: const EdgeInsetsDirectional.only(bottom: 28),
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 14),
                    child: PlaceHeader(
                      title: 'فلاش كاردز بلينغو',
                      subtitle: 'مراجعة أسرع .. وتذكّر أذكى',
                      icon: Icons.psychology_rounded,
                      assetPath: 'assets/brand/flashcards_header.png',
                    ),
                  ),
                  if (pills.length > 1)
                    PillSelector<String?>(
                      key: const Key('plengoCards.pills'),
                      options: [
                        const PlengoOption(null, 'الكل'),
                        for (final g in pills) PlengoOption(g.subjectId, g.subjectNameAr),
                      ],
                      selected: selected,
                      onSelected: (id) => setState(() => _subjectId = id),
                    ),
                  if (groups.isEmpty)
                    const PlengoEmptyState(
                      title: 'لا مجموعات بعد',
                      message: 'ستظهر هنا مجموعات بلينغو لمواد صفّك',
                      icon: Icons.style_rounded,
                      hue: PlengoColors.pink,
                    ),
                  for (final g in groups) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
                      child: SectionHeader(g.subjectNameAr, top: 18),
                    ),
                    for (final d in g.decks)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          PlengoSpace.screen,
                          0,
                          PlengoSpace.screen,
                          PlengoSpace.listGap,
                        ),
                        child: PlengoDeckTile(
                          deck: d,
                          subjectName: g.subjectNameAr,
                          onTap: () => context.push('${Routes.plengoCards}/decks/${d.id}'),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One Plengo deck as a product: a soft card in the subject's hue with the title, «فلاش كاردز
/// <المادة>», the card count and «مقفل» or «مجانية», and the product box (the deck cover, 3:4) at
/// the end; a coloured box with the title when there is no cover.
class PlengoDeckTile extends StatelessWidget {
  const PlengoDeckTile({super.key, required this.deck, required this.subjectName, required this.onTap});

  final StudentDeck deck;
  final String subjectName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = subjectHue(deck.subjectId);
    final bg = s.isDark ? Color.alphaBlend(hue.base.withValues(alpha: 0.12), s.card) : hue.soft;
    final status = deck.locked
        ? 'مقفل'
        : deck.isFree
        ? 'مجانية'
        : null;
    return PlengoCard(
      key: Key('plengoDeck.${deck.id}'),
      color: bg,
      radius: PlengoRadius.row,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
      onTap: onTap,
      semanticsLabel: [deck.titleAr, 'فلاش كاردز $subjectName', cardCountLabel(deck.cardCount), ?status].join('، '),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.titleAr, style: PlengoType.section.copyWith(color: s.ink)),
                  Text(
                    'فلاش كاردز $subjectName',
                    style: PlengoType.caption.copyWith(color: hueText(context, hue)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PlengoChip(
                        label: cardCountLabel(deck.cardCount),
                        hue: hue,
                        icon: Icons.style_outlined,
                        background: s.card,
                        foreground: hueText(context, hue),
                      ),
                      if (deck.locked)
                        const PlengoChip(label: 'مقفل', hue: PlengoColors.red, icon: Icons.lock_outline_rounded)
                      else if (deck.isFree)
                        const PlengoChip(label: 'مجانية', hue: PlengoColors.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DeckCover(deck: deck, width: 78),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: s.mute),
          ],
        ),
      ),
    );
  }
}

/// The product box of a deck (3:4): its cover image, else a box in the subject's hue with the title.
class DeckCover extends StatelessWidget {
  const DeckCover({super.key, required this.deck, this.width = 78});

  final StudentDeck deck;
  final double width;

  @override
  Widget build(BuildContext context) {
    final hue = subjectHue(deck.subjectId);
    final fallback = Container(
      key: const Key('deckCover.fallback'),
      color: hue.fill,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(
        deck.titleAr,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
        style: PlengoType.chip.copyWith(color: hue.onFill, fontSize: 11, height: 1.3),
      ),
    );
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 4), blurRadius: 8)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: deck.coverUrl == null
                ? fallback
                : CachedNetworkImage(
                    imageUrl: deck.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => ColoredBox(color: hue.soft),
                    errorWidget: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
