import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/srs/queue.dart';
import '../../core/srs/scheduler.dart';
import '../../core/srs/srs_key.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../bookmarks/bookmark_providers.dart';
import '../home/streak_moment.dart';
import '../reports/report_sheet.dart';
import 'card_face.dart';
import 'flashcard_providers.dart';
import 'flashcard_ui.dart';

/// Study mode (مراجعة): spaced repetition with three buttons and undo (spec §13.3). Keyboard on web:
/// Space flips, 1/2/3 rate Again/Good/Easy, Z undoes the last rating. Redesign: V-Flashcards.
class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key, required this.source, required this.title});

  final StudySource source;
  final String title;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  /// Ratings given in this visit, newest last (for the done summary; undo pops the last one).
  final _ratings = <Rating>[];

  /// The most cards left at once in this visit: the session bar's 100%.
  int _peak = 0;

  StudySource get _source => widget.source;

  Future<void> _rate(StudyState s, Rating rating) async {
    if (s.current == null || !s.flipped) return;
    _ratings.add(rating);
    await ref.read(studyControllerProvider(_source).notifier).rate(rating);
    if (mounted) setState(() {});
  }

  Future<void> _undo(StudyState s) async {
    if (s.undoCount == 0) return;
    if (_ratings.isNotEmpty) _ratings.removeLast();
    await ref.read(studyControllerProvider(_source).notifier).undo();
    if (mounted) setState(() {});
  }

  Future<void> _home() async {
    await maybeShowStreakMoment(context, ref);
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final study = ref.watch(studyControllerProvider(_source));
    final ctl = ref.read(studyControllerProvider(_source).notifier);
    return AsyncView(
      value: study,
      onRetry: () => ref.invalidate(studyControllerProvider(_source)),
      frame: (child) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const PlengoCloseButton(tooltip: 'إنهاء المراجعة'),
          leadingWidth: kPlengoLeadingWidth,
          title: Text(widget.title),
        ),
        body: child,
      ),
      data: (s) {
        final card = s.current;
        final q = s.queue;
        final left = q.newCount + q.learningCount + q.reviewCount;
        if (left > _peak) _peak = left;
        if (card == null) {
          return Scaffold(
            body: SafeArea(
              child: _Done(nextDueAt: q.nextDueAt, ratings: _ratings, source: _source, onHome: _home),
            ),
          );
        }
        final previews = s.flipped ? ctl.previews() : null;
        final upcoming = s.order.where((id) => id != q.next).take(3);
        ref.read(cardImagePrefetchProvider)(context, [for (final id in upcoming) ...s.cards[id]!.images]);
        final bucket = SrsBucket.of(s.states[card.key]?.state);
        final done = _peak == 0 ? 0.0 : (_peak - left) / _peak;
        final st = context.surface;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.space): ctl.flip,
                const SingleActivator(LogicalKeyboardKey.digit1): () => _rate(s, Rating.again),
                const SingleActivator(LogicalKeyboardKey.digit2): () => _rate(s, Rating.good),
                const SingleActivator(LogicalKeyboardKey.digit3): () => _rate(s, Rating.easy),
                const SingleActivator(LogicalKeyboardKey.keyZ): () => _undo(s),
              },
              child: Focus(
                autofocus: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 8, 4),
                          child: Row(
                            children: [
                              const PlengoCloseButton(tooltip: 'إنهاء المراجعة'),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _Counts(queue: q, current: bucket, title: widget.title),
                              ),
                              const SizedBox(width: 6),
                              _CardMenu(card: card),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Semantics(
                            label: 'تقدّم الجلسة',
                            value: '${(done * 100).round()}%',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(PlengoRadius.pill),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: done),
                                duration: PlengoMotion.of(context, PlengoMotion.progress),
                                builder: (context, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 6,
                                  color: st.action,
                                  backgroundColor: st.track,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) => SingleChildScrollView(
                              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 12),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: (box.maxHeight - 26).clamp(0, double.infinity)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: FlashcardView(
                                        card: card,
                                        flipped: s.flipped,
                                        onTap: ctl.flip,
                                        maxHeight: (box.maxHeight - 70).clamp(200, double.infinity),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (!s.flipped) ...[
                                          Icon(Icons.touch_app_outlined, size: 18, color: st.mute),
                                          const SizedBox(width: 6),
                                        ],
                                        Flexible(
                                          child: Text(
                                            s.flipped ? 'كيف كان تذكّرك؟' : 'اضغط على البطاقة لعرض الإجابة',
                                            textAlign: TextAlign.center,
                                            style: PlengoType.caption.copyWith(color: st.mute),
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
                        BottomPanel(
                          children: [
                            // Fixed minimum height so the card does not jump when the buttons change.
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 70),
                              child: Center(
                                child: previews == null
                                    ? PlengoButton(label: 'اقلب البطاقة', onPressed: ctl.flip)
                                    : IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            for (final (rating, label) in [
                                              (Rating.again, 'مرة أخرى'),
                                              (Rating.good, 'جيد'),
                                              (Rating.easy, 'سهل'),
                                            ]) ...[
                                              Expanded(
                                                child: _RatingButton(
                                                  rating: rating,
                                                  label: label,
                                                  interval: previews[rating]!.label,
                                                  onPressed: () => _rate(s, rating),
                                                ),
                                              ),
                                              if (rating != Rating.easy) const SizedBox(width: 8),
                                            ],
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            // «تراجع» only after the first rating; its space is kept so nothing moves.
                            Visibility(
                              visible: s.undoCount > 0,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Center(
                                child: PlengoButton(
                                  label: 'تراجع',
                                  icon: Icons.undo_rounded,
                                  variant: PlengoButtonVariant.ghost,
                                  size: PlengoButtonSize.small,
                                  onPressed: s.undoCount > 0 ? () => _undo(s) : null,
                                ),
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
          ),
        );
      },
    );
  }
}

/// «جديدة · تعلّم · مراجعة» left in the session, live; the current card's bucket is underlined.
class _Counts extends StatelessWidget {
  const _Counts({required this.queue, required this.current, required this.title});

  final QueueSnapshot queue;
  final SrsBucket current;
  final String title;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final items = [
      (SrsBucket.fresh, 'جديدة', queue.newCount),
      (SrsBucket.learning, 'تعلّم', queue.learningCount),
      (SrsBucket.review, 'مراجعة', queue.reviewCount),
    ];
    return Semantics(
      container: true,
      label:
          '$title. المتبقي في الجلسة: ${[for (final (_, t, n) in items) '$t $n'].join('، ')}. البطاقة الحالية: ${current == SrsBucket.learning ? 'تعلّم' : current.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, (bucket, label, n)) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 14),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$n',
                    key: Key('count-${bucket.name}'),
                    style: PlengoType.section.copyWith(fontSize: 20, height: 1.2, color: hueText(context, bucket.hue)),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.chip.copyWith(fontSize: 11, color: s.ink),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 3,
                    width: 28,
                    decoration: BoxDecoration(
                      color: bucket == current ? hueText(context, bucket.hue) : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ⋮ menu of the current card: save it and, for official cards, report a problem.
class _CardMenu extends ConsumerWidget {
  const _CardMenu({required this.card});

  final StudyCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final own = SrsKey.isUserCard(card.key);
    final type = own ? BookmarkItemType.userCard : BookmarkItemType.flashcard;
    final id = own ? SrsKey.idOf(card.key) : card.key;
    final saved = ref.watch(bookmarkKeysProvider).value?.contains(bookmarkKey(type, id)) ?? false;
    final reportsOn = ref.watch(contentReportsEnabledProvider) && !own;
    final s = context.surface;
    return PopupMenuButton<String>(
      tooltip: reportsOn ? 'خيارات البطاقة: حفظ، إبلاغ عن مشكلة' : 'خيارات البطاقة: حفظ',
      onSelected: (v) async {
        if (v == 'report') {
          await showReportSheet(context, ref, ReportItemType.flashcard, card.key);
          return;
        }
        try {
          await ref.read(bookmarkKeysProvider.notifier).toggle(type, id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الحفظ، حاول مرة أخرى')));
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'save',
          child: Row(
            children: [
              Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
              const SizedBox(width: 10),
              Text(saved ? 'إزالة من المحفوظات' : 'حفظ'),
            ],
          ),
        ),
        if (reportsOn)
          const PopupMenuItem(
            value: 'report',
            child: Row(children: [Icon(Icons.flag_outlined), SizedBox(width: 10), Text('إبلاغ عن مشكلة')]),
          ),
      ],
      child: SizedBox.square(
        dimension: PlengoSpace.minTouch,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: BorderRadius.circular(PlengoRadius.iconButton),
            border: s.isDark ? Border.all(color: s.line) : null,
            boxShadow: s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
          ),
          child: Icon(Icons.more_vert_rounded, color: s.ink),
        ),
      ),
    );
  }
}

/// One of the three ratings (§13.3) with the predicted interval under its label: «مرة أخرى» strong
/// red with white text, «جيد» yellow and «سهل» green with dark text; 3D like the other buttons.
class _RatingButton extends StatefulWidget {
  const _RatingButton({required this.rating, required this.label, required this.interval, required this.onPressed});

  final Rating rating;
  final String label;
  final String interval;
  final VoidCallback onPressed;

  @override
  State<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends State<_RatingButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color shadow) = switch (widget.rating) {
      Rating.again => (PlengoColors.redStrong, Colors.white, PlengoColors.red.shadow),
      Rating.good => (PlengoColors.yellow.base, PlengoColors.ink, PlengoColors.yellow.shadow),
      Rating.easy => (PlengoColors.green.base, PlengoColors.ink, PlengoColors.green.shadow),
    };
    final r = BorderRadius.circular(PlengoRadius.button);
    return Semantics(
      button: true,
      label: '${widget.label}، ${widget.interval}',
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: PlengoMotion.of(context, PlengoMotion.press),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: r,
          boxShadow: _pressed ? const [] : [BoxShadow(color: shadow, offset: const Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            splashFactory: NoSplash.splashFactory,
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 66),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: PlengoType.button.copyWith(color: fg),
                    ),
                    Text(
                      widget.interval,
                      textAlign: TextAlign.center,
                      style: PlengoType.caption.copyWith(fontWeight: FontWeight.w500, color: fg, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «أنهيت مراجعة اليوم»: trophy, when the next card is due, the session's ratings, then home.
class _Done extends ConsumerWidget {
  const _Done({required this.nextDueAt, required this.ratings, required this.source, required this.onHome});

  final int? nextDueAt;
  final List<Rating> ratings;
  final StudySource source;
  final Future<void> Function() onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    int count(Rating r) => ratings.where((x) => x == r).length;
    final browse = source.deckId != null
        ? '${Routes.decks}/${source.deckId}/browse'
        : source.myDeckId != null
        ? '${Routes.myDeckStudy}/${source.myDeckId}/browse'
        : null;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  ConfettiDots(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: PlengoColors.yellow.base,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: PlengoColors.yellow.soft, spreadRadius: 10)],
                      ),
                      child: const ExcludeSemantics(
                        child: Icon(Icons.emoji_events_rounded, size: 64, color: PlengoColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(
                      'أنهيت مراجعة اليوم',
                      textAlign: TextAlign.center,
                      style: PlengoType.title.copyWith(color: s.ink),
                    ),
                  ),
                  if (nextDueAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'البطاقة التالية: ${nextDueLabel(nextDueAt!, ref.read(clockProvider)())}',
                      textAlign: TextAlign.center,
                      style: PlengoType.sub.copyWith(color: s.mute),
                    ),
                  ],
                  if (ratings.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PlengoChip(label: 'مرة أخرى ${count(Rating.again)}', hue: PlengoColors.red),
                        PlengoChip(label: 'جيد ${count(Rating.good)}', hue: PlengoColors.yellow),
                        PlengoChip(label: 'سهل ${count(Rating.easy)}', hue: PlengoColors.green),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        BottomPanel(
          children: [
            PlengoButton(label: 'العودة إلى الرئيسية', onPressed: onHome),
            if (browse != null)
              PlengoButton(
                label: 'تصفح المجموعة',
                variant: PlengoButtonVariant.ghost,
                onPressed: () => context.pushReplacement(browse),
              ),
          ],
        ),
      ],
    );
  }
}
