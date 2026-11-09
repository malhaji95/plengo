import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../my_decks/add_to_my_deck.dart';
import '../my_decks/my_decks_providers.dart';
import '../reports/report_sheet.dart';
import 'card_face.dart';
import 'flashcard_providers.dart';
import 'flashcard_ui.dart';

/// Browse mode (تصفح) of an official deck: flip, السابق / التالي, no scheduling (spec §13.2). Each
/// card can be added to the student's decks (§13.9) or reported (§21). Redesign: V-FcBrowse.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(browseCardsProvider(deckId));
    final decksOn = ref.watch(studentDecksEnabledProvider);
    final reportsOn = ref.watch(contentReportsEnabledProvider);
    return AsyncView(
      value: data,
      onRetry: () => ref.invalidate(browseCardsProvider(deckId)),
      frame: (child) => Scaffold(appBar: plengoAppBar(context), body: child),
      data: (d) => CardBrowser(
        title: d.title,
        cards: d.cards,
        onAdd: !decksOn
            ? null
            : (card) async {
                final official = await officialCardFor(ref, deckId, card.key);
                if (official == null || !context.mounted) return false;
                return addToMyDeck(context, ref, official);
              },
        onReport: !reportsOn ? null : (card) => showReportSheet(context, ref, ReportItemType.flashcard, card.key),
      ),
    );
  }
}

/// Browse mode of one of the student's decks (works offline).
class MyBrowseScreen extends ConsumerWidget {
  const MyBrowseScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(myDeckProvider(deckId)).value;
    final cards = ref.watch(myDeckCardsProvider(deckId));
    return AsyncView(
      value: cards,
      onRetry: () => ref.invalidate(myDeckCardsProvider(deckId)),
      frame: (child) => Scaffold(appBar: plengoAppBar(context), body: child),
      data: (rows) => CardBrowser(
        title: deck?.name ?? 'تصفح',
        cards: [
          for (final r in rows)
            if (!r.locked) StudyCard.own(r),
        ],
      ),
    );
  }
}

/// The browse UI: «5 / 131» with a thin bar, the card (tap flips it, a horizontal swipe moves in the
/// reading direction), «السابق | اقلب البطاقة | التالي», and «+ أضف إلى بطاقاتي» when [onAdd] is set.
/// Keyboard on web: Space flips; the arrow pointing in the reading direction (left in Arabic) goes to
/// the next card.
class CardBrowser extends ConsumerStatefulWidget {
  const CardBrowser({super.key, required this.title, required this.cards, this.onAdd, this.onReport});

  final String title;
  final List<StudyCard> cards;

  /// Adds the card to the student's decks; resolves to whether it was added.
  final Future<bool> Function(StudyCard card)? onAdd;
  final void Function(StudyCard card)? onReport;

  @override
  ConsumerState<CardBrowser> createState() => _CardBrowserState();
}

class _CardBrowserState extends ConsumerState<CardBrowser> {
  int _index = 0;
  bool _flipped = false;

  /// Cards added to the student's decks during this visit.
  final _added = <String>{};

  void _go(int delta, int count) {
    final next = (_index + delta).clamp(0, count - 1);
    if (next != _index) setState(() => (_index = next, _flipped = false));
  }

  void _flip() => setState(() => _flipped = !_flipped);

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final s = context.surface;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: plengoAppBar(context, title: widget.title),
        body: const EmptyState('لا بطاقات في هذه المجموعة'),
      );
    }
    _index = _index.clamp(0, cards.length - 1);
    final card = cards[_index];
    final count = cards.length;
    final face = _flipped ? card.back : card.front;
    final added = _added.contains(card.key);
    ref.read(cardImagePrefetchProvider)(context, [for (final c in cards.skip(_index + 1).take(3)) ...c.images]);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop() ? const PlengoBackButton() : null,
        leadingWidth: kPlengoLeadingWidth,
        centerTitle: true,
        title: Semantics(
          label: 'البطاقة ${_index + 1} من $count',
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_index + 1} / $count',
                textDirection: TextDirection.ltr,
                style: PlengoType.rowTitle.copyWith(color: s.ink),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PlengoRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / count,
                    minHeight: 6,
                    color: s.action,
                    backgroundColor: s.track,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (faceHasImage(face))
            PlengoIconButton(
              icon: Icons.zoom_in_rounded,
              tooltip: 'تكبير البطاقة',
              onPressed: () => showCardZoom(context, face),
            ),
          if (widget.onReport != null) ...[
            const SizedBox(width: 6),
            PlengoIconButton(
              icon: Icons.flag_outlined,
              tooltip: 'إبلاغ عن مشكلة',
              onPressed: () => widget.onReport!(card),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _flip,
          SingleActivator(rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight): () => _go(1, count),
          SingleActivator(rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft): () => _go(-1, count),
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      // The next card lies in the reading direction: a swipe towards the end edge
                      // (left to right in Arabic) brings it in.
                      onHorizontalDragEnd: (e) {
                        final v = e.primaryVelocity ?? 0;
                        if (v.abs() < 200) return;
                        final forward = rtl ? v > 0 : v < 0;
                        _go(forward ? 1 : -1, count);
                      },
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: (box.maxHeight - 20).clamp(0, double.infinity)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: PlengoType.chip.copyWith(color: s.mute),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: FlashcardView(
                                    card: card,
                                    flipped: _flipped,
                                    onTap: _flip,
                                    maxHeight: (box.maxHeight - 90).clamp(200, double.infinity),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'اضغط على البطاقة أو اسحب يميناً ويساراً للتنقّل',
                                  textAlign: TextAlign.center,
                                  style: PlengoType.caption.copyWith(color: s.mute),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BottomPanel(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: PlengoButton(
                              label: 'السابق',
                              semanticsLabel: 'البطاقة السابقة',
                              variant: PlengoButtonVariant.secondary,
                              onPressed: _index > 0 ? () => _go(-1, count) : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 13,
                            child: PlengoButton(label: 'اقلب البطاقة', onPressed: _flip),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 10,
                            child: PlengoButton(
                              label: 'التالي',
                              semanticsLabel: 'البطاقة التالية',
                              variant: PlengoButtonVariant.secondary,
                              onPressed: _index < count - 1 ? () => _go(1, count) : null,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onAdd != null)
                        Semantics(
                          toggled: added,
                          child: PlengoButton(
                            key: const Key('add-to-my-decks'),
                            label: added ? 'أُضيفت البطاقة إلى مجموعتك' : 'أضف إلى بطاقاتي',
                            icon: added ? Icons.check_rounded : Icons.add_rounded,
                            semanticsLabel: added ? 'أُضيفت البطاقة إلى مجموعتك' : 'أضف إلى بطاقاتي',
                            variant: PlengoButtonVariant.ghost,
                            onPressed: () async {
                              final ok = await widget.onAdd!(card);
                              if (ok && mounted) setState(() => _added.add(card.key));
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
