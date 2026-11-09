import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/srs/queue.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../access/access_banner.dart';
import '../bookmarks/bookmark_button.dart';
import '../offline/download_widgets.dart';
import '../subjects/catalog_providers.dart';
import 'decks_screen.dart';
import 'flashcard_providers.dart';
import 'flashcard_ui.dart';

/// Today's queue of one deck from the device's SRS states (DECISIONS #9): what a study session of
/// this deck would show now, with the same daily limits.
final deckQueueProvider = FutureProvider.autoDispose.family<QueueSnapshot, String>((ref, deckId) async {
  final cards = await ref.watch(browseCardsProvider(deckId).future);
  final order = [for (final c in cards.cards) c.key];
  final store = ref.read(srsStoreProvider);
  final states = await store.statesFor(order);
  final now = ref.read(clockProvider)();
  final limits = ref.read(srsLimitsProvider);
  final done = await store.todayCounts(now);
  return buildQueue(
    order: order,
    states: states,
    now: now,
    newLimit: limits.newPerDay - done.newDone,
    reviewLimit: limits.maxReviews - done.reviewsDone,
  );
});

/// Deck details with its two modes: تصفح (Browse) and مراجعة (Study) (spec §13.2). Redesign: V-FcDeck.
class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider(deckId));
    return Scaffold(
      appBar: plengoAppBar(
        context,
        actions: [BookmarkButton(type: BookmarkItemType.deck, id: deckId)],
      ),
      body: AsyncView(
        value: deck,
        onRetry: () => ref.invalidate(deckProvider(deckId)),
        data: (d) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28),
              children: [
                _Header(deck: d),
                if (d.description != null) ...[
                  const SizedBox(height: 12),
                  Text(d.description!, style: PlengoType.sub.copyWith(color: context.surface.mute)),
                ],
                const SizedBox(height: 16),
                if (d.locked)
                  const LockedNotice()
                else ...[
                  _TodayCard(deckId: deckId),
                  const SizedBox(height: 16),
                  OfflineDownloadTile(
                    scope: (subjectId: d.subjectId, teacherTrackId: d.teacherTrackId),
                    deckId: deckId,
                    label: 'تحميل البطاقات',
                    doneLabel: 'البطاقات محمّلة',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail, «المادة · الوحدة», the name and the count / free chips.
class _Header extends ConsumerWidget {
  const _Header({required this.deck});

  final StudentDeck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final hue = subjectHue(deck.subjectId);
    // Names are a nicety: without the outline (offline) the caption is left out.
    final outline = ref.watch(subjectOutlineProvider(deck.subjectId)).value;
    final unit = outline?.units.where((u) => u.id == deck.unitId).firstOrNull;
    final caption = outline == null ? null : [outline.subject.nameAr, ?unit?.titleAr].join(' · ');
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 84,
            height: 110,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hue.base,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 5))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: deck.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: deck.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _Blank(hue: hue),
                    )
                  : _Blank(hue: hue),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (caption != null) Text(caption, style: PlengoType.chip.copyWith(color: hueText(context, hue))),
              Semantics(
                header: true,
                child: Text(deck.titleAr, style: PlengoType.title.copyWith(fontSize: 22, color: s.ink)),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PlengoChip(label: cardCountLabel(deck.cardCount), hue: hue),
                  if (deck.isFree) const PlengoChip(label: 'مجانية', hue: PlengoColors.green),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Blank extends StatelessWidget {
  const _Blank({required this.hue});

  final PlengoHue hue;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Center(child: Icon(Icons.style_rounded, size: 34, color: hue.ink)),
  );
}

/// «مستحقة اليوم: N · حوالي M دقائق», the three bucket chips and the two modes. With nothing due:
/// «البطاقة التالية: …».
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final queue = ref.watch(deckQueueProvider(deckId)).value;
    final due = queue == null ? null : queue.newCount + queue.learningCount + queue.reviewCount;
    Future<void> open(String mode) async {
      await context.push('${Routes.decks}/$deckId/$mode');
      ref.invalidate(deckQueueProvider(deckId));
    }

    return PlengoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (queue != null && due != null) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('مستحقة اليوم: $due', style: PlengoType.rowTitle.copyWith(color: s.ink)),
                if (due > 0) Text(studyTimeLabel(due), style: PlengoType.caption.copyWith(color: s.mute)),
              ],
            ),
            const SizedBox(height: 10),
            BucketChips(fresh: queue.newCount, learning: queue.learningCount, review: queue.reviewCount),
            if (due == 0 && queue.nextDueAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'البطاقة التالية: ${nextDueLabel(queue.nextDueAt!, ref.read(clockProvider)())}',
                style: PlengoType.sub.copyWith(color: s.mute),
              ),
            ],
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                flex: 14,
                child: PlengoButton(label: 'مراجعة', icon: Icons.psychology_outlined, onPressed: () => open('study')),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 10,
                child: PlengoButton(
                  label: 'تصفح',
                  variant: PlengoButtonVariant.secondary,
                  onPressed: () => open('browse'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
