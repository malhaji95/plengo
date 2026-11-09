import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/flashcard_repository.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'flashcard_providers.dart';
import 'flashcard_ui.dart';

/// Arabic count agreement: بطاقة واحدة، بطاقتان، 3–10 بطاقات، 11+ بطاقة.
String cardCountLabel(int n) => switch (n) {
  0 => 'لا بطاقات بعد',
  1 => 'بطاقة واحدة',
  2 => 'بطاقتان',
  >= 3 && <= 10 => '$n بطاقات',
  _ => '$n بطاقة',
};

/// Every due card of a subject (one call); local ratings are pushed first so the server's list is current.
final subjectDueProvider = FutureProvider.autoDispose.family<DueCards, String>((ref, subjectId) async {
  await ref.read(srsSyncProvider).syncNow();
  return ref.watch(flashcardRepositoryProvider).due(subjectId: subjectId);
});

/// Due cards per deck id, from [subjectDueProvider] grouped by `card.deckId` (DECISIONS #8).
Map<String, int> dueByDeck(DueCards due) {
  final out = <String, int>{};
  for (final d in due.cards) {
    out[d.card.deckId] = (out[d.card.deckId] ?? 0) + 1;
  }
  return out;
}

/// Official decks of a subject's general content or of a track (spec §13.1). Locked decks show as
/// metadata only (§8.6). Redesign: V-FcDecks.
class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key, required this.query, required this.title});

  final DeckQuery query;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider(query));
    final subjectId = query.subjectId;
    // Due counts are extra: without them (offline, error) the rows simply show no due chip.
    final due = ref.watch(subjectDueProvider(subjectId)).value;
    final perDeck = due == null ? null : dueByDeck(due);
    final s = context.surface;
    return Scaffold(
      appBar: plengoAppBar(context, title: title),
      body: AsyncView(
        value: decks,
        onRetry: () => ref.invalidate(decksProvider(query)),
        data: (list) => list.isEmpty
            ? const EmptyState('لا توجد بطاقات هنا بعد', icon: Icons.style_outlined)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28),
                    children: [
                      Text(groupCountLabel(list.length), style: PlengoType.chip.copyWith(color: s.mute)),
                      const SizedBox(height: 12),
                      if (due != null && due.cards.isNotEmpty) ...[
                        _DueSummary(
                          count: due.cards.length,
                          onStart: () async {
                            await context.push(
                              Uri(path: Routes.dueStudy, queryParameters: {'subjectId': subjectId}).toString(),
                            );
                            ref.invalidate(subjectDueProvider(subjectId));
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final d in list) ...[
                        DeckTile(deck: d, dueCount: perDeck == null ? null : (perDeck[d.id] ?? 0)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'بطاقات من المحتوى الرسمي · يمكنك تحميل أي مجموعة لاستخدامها دون اتصال',
                        textAlign: TextAlign.center,
                        style: PlengoType.caption.copyWith(color: s.mute),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// «كل البطاقات المستحقة: N» with «ابدأ المراجعة» on a yellow-soft card.
class _DueSummary extends StatelessWidget {
  const _DueSummary({required this.count, required this.onStart});

  final int count;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final yellow = PlengoColors.yellow;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('كل البطاقات المستحقة: $count', style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink)),
        Text('من كل مجموعات المادة', style: PlengoType.caption.copyWith(color: yellow.ink)),
      ],
    );
    final button = PlengoButton(label: 'ابدأ المراجعة', size: PlengoButtonSize.small, onPressed: onStart);
    return PlengoCard(
      color: yellow.soft,
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow = box.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.1;
          final icon = SubjectIconTile(icon: Icons.style_rounded, hue: yellow);
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 12),
                button,
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: text),
              const SizedBox(width: 8),
              button,
            ],
          );
        },
      ),
    );
  }
}

/// One official deck in a list (V-FcDecks): a subject-colour strip at the start edge, an icon tile,
/// the name, «N بطاقة · مجانية», and a trailing chip: «N مستحقة» / «لا شيء مستحق» when [dueCount]
/// is known, or «مقفلة» with a lock for a locked deck (§8.7). Never colour alone: every chip has text.
class DeckTile extends StatelessWidget {
  const DeckTile({super.key, required this.deck, this.dueCount});

  final StudentDeck deck;

  /// Cards of this deck due now; null when unknown (no chip).
  final int? dueCount;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = subjectHue(deck.subjectId);
    final due = dueCount;
    final Widget? chip = deck.locked
        ? const PlengoChip(label: 'مقفلة', hue: PlengoColors.red, icon: Icons.lock_rounded)
        : due == null
        ? null
        : due > 0
        ? PlengoChip(label: '$due مستحقة', hue: PlengoColors.yellow)
        : const PlengoChip(label: 'لا شيء مستحق', hue: PlengoColors.green, icon: Icons.check_rounded);
    final chipText = deck.locked
        ? 'مقفلة'
        : due == null
        ? null
        : due > 0
        ? '$due مستحقة'
        : 'لا شيء مستحق';
    // The gap under each row is part of the tile (lists elsewhere, e.g. the lesson page, rely on it).
    final row = StripRow(
      color: hue.base,
      onTap: () => context.go('${Routes.decks}/${deck.id}'),
      semanticsLabel: [deck.titleAr, cardCountLabel(deck.cardCount), if (deck.isFree) 'مجانية', ?chipText].join('، '),
      child: Row(
        children: [
          SubjectIconTile(icon: Icons.style_rounded, hue: hue, soft: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(deck.titleAr, style: PlengoType.rowTitle.copyWith(color: s.ink)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: cardCountLabel(deck.cardCount)),
                      if (deck.isFree) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: 'مجانية',
                          style: TextStyle(color: hueText(context, PlengoColors.green), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  style: PlengoType.caption.copyWith(color: s.mute),
                ),
              ],
            ),
          ),
          if (chip != null) ...[const SizedBox(width: 8), chip],
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: PlengoSpace.listGap),
      child: row,
    );
  }
}

/// `/subjects/:id/decks`.
class SubjectDecksRoute extends ConsumerWidget {
  const SubjectDecksRoute({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    return DecksScreen(
      query: (subjectId: subjectId, teacherTrackId: null, unitId: null, lessonId: null),
      title: outline != null ? 'بطاقات ${outline.subject.nameAr}' : 'البطاقات التعليمية',
    );
  }
}

/// `/tracks/:id/decks`.
class TrackDecksRoute extends ConsumerWidget {
  const TrackDecksRoute({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    return detail.when(
      data: (d) => DecksScreen(
        query: (subjectId: d.subject.id, teacherTrackId: trackId, unitId: null, lessonId: null),
        title: 'بطاقات ${d.track.titleAr}',
      ),
      loading: () => Scaffold(
        appBar: plengoAppBar(context),
        body: const Align(alignment: Alignment.topCenter, child: PlengoLoadingSkeleton()),
      ),
      error: (_, _) => Scaffold(
        appBar: plengoAppBar(context),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(trackProvider(trackId)),
          data: (_) => const SizedBox(),
        ),
      ),
    );
  }
}
