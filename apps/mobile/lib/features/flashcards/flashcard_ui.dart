import 'package:flutter/material.dart';

import '../../core/srs/scheduler.dart';
import '../../shared/ui/ui.dart';

/// Pieces shared by the flashcard, review, mistakes, stats, my-decks and saved screens (redesign v2).

/// The app bar of a redesigned inner screen: the soft back square (only when there is somewhere to go
/// back to), the 20/700 title and [actions].
PreferredSizeWidget plengoAppBar(BuildContext context, {String? title, List<Widget>? actions, Widget? leading}) {
  final canPop = Navigator.of(context).canPop();
  return AppBar(
    automaticallyImplyLeading: false,
    leading: leading ?? (canPop ? const PlengoBackButton() : null),
    leadingWidth: kPlengoLeadingWidth,
    titleSpacing: leading != null || canPop ? 4 : PlengoSpace.screen,
    title: title == null ? null : Text(title),
    actions: [...?actions, const SizedBox(width: 8)],
  );
}

/// Arabic count agreement for a noun after a number: 1 → [one], 2 → [two], 3–10 → [few], else [many].
String arabicCount(int n, {required String one, required String two, required String few, required String many}) =>
    switch (n) {
      1 => one,
      2 => two,
      >= 3 && <= 10 => '$n $few',
      _ => '$n $many',
    };

/// «N مجموعات».
String groupCountLabel(int n) => arabicCount(n, one: 'مجموعة واحدة', two: 'مجموعتان', few: 'مجموعات', many: 'مجموعة');

/// The noun after a big card number: «بطاقة» / «بطاقتان» / «بطاقات».
String cardNoun(int n) => switch (n) {
  2 => 'بطاقتان',
  >= 3 && <= 10 => 'بطاقات',
  _ => 'بطاقة',
};

/// Seconds a due card takes on average (DECISIONS #9).
const secondsPerCard = 8;

/// Whole minutes for [due] cards, rounded up (DECISIONS #9).
int studyMinutes(int due) => (due * secondsPerCard / 60).ceil();

/// «حوالي N دقائق» for [due] cards.
String studyTimeLabel(int due) {
  final m = studyMinutes(due);
  return 'حوالي ${arabicCount(m, one: 'دقيقة', two: 'دقيقتين', few: 'دقائق', many: 'دقيقة')}';
}

/// When the next card is due, in Damascus time: «اليوم 19:00», «غداً 07:30» or «2026/10/2 19:00».
String nextDueLabel(int dueAt, int now) {
  DateTime local(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(const Duration(hours: 3));
  String two(int v) => v.toString().padLeft(2, '0');
  final d = local(dueAt);
  final n = local(now);
  final days = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(n.year, n.month, n.day)).inDays;
  final time = '${two(d.hour)}:${two(d.minute)}';
  return switch (days) {
    <= 0 => 'اليوم $time',
    1 => 'غداً $time',
    _ => '${d.year}/${d.month}/${d.day} $time',
  };
}

/// Text in a hue on the neutral background: its ink in light mode, the bright base in dark mode (the
/// dark-mode action blue for blue, which passes 4.5:1 on #151515).
Color hueText(BuildContext context, PlengoHue hue) {
  final s = context.surface;
  if (!s.isDark) return hue.ink;
  return hue == PlengoColors.blue ? s.action : hue.base;
}

/// The SRS bucket a card is counted in: new (blue), learning (orange) or review (green).
enum SrsBucket {
  fresh('جديدة', PlengoColors.blue),
  learning('قيد التعلم', PlengoColors.orange),
  review('مراجعة', PlengoColors.green);

  const SrsBucket(this.label, this.hue);

  final String label;
  final PlengoHue hue;

  static SrsBucket of(CardStateName? s) => switch (s) {
    null || CardStateName.newCard => fresh,
    CardStateName.review => review,
    _ => learning,
  };
}

/// Three chips «جديدة N · قيد التعلم N · مراجعة N»; [learningLabel] lets a screen use «تعلّم».
class BucketChips extends StatelessWidget {
  const BucketChips({
    super.key,
    required this.fresh,
    required this.learning,
    required this.review,
    this.learningLabel = 'قيد التعلم',
  });

  final int fresh;
  final int learning;
  final int review;
  final String learningLabel;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      PlengoChip(label: '${SrsBucket.fresh.label} $fresh', hue: SrsBucket.fresh.hue),
      PlengoChip(label: '$learningLabel $learning', hue: SrsBucket.learning.hue),
      PlengoChip(label: '${SrsBucket.review.label} $review', hue: SrsBucket.review.hue),
    ],
  );
}

/// A coloured strip on the start edge of a row (deck colour), then [child]. Radius 20 like a list
/// row; the whole row is one button when [onTap] is set.
class StripRow extends StatelessWidget {
  const StripRow({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.semanticsLabel,
    this.stripWidth = 8,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(PlengoRadius.row);
    return Semantics(
      button: onTap != null,
      container: true,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: r,
          border: s.isDark ? Border.all(color: s.line) : null,
          boxShadow: s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: stripWidth,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(8)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: PlengoSpace.row),
                        child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10), child: child),
                      ),
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

/// A soft-coloured tile with an icon square, a title and a caption (Review tab shortcuts).
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.hue,
    required this.title,
    this.caption,
    required this.onTap,
  });

  final IconData icon;
  final PlengoHue hue;
  final String title;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(PlengoRadius.row);
    return Semantics(
      button: true,
      container: true,
      label: [title, ?caption].join('، '),
      excludeSemantics: true,
      child: Material(
        color: hue.soft,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubjectIconTile(icon: icon, hue: hue, size: 40),
                const SizedBox(height: 10),
                Text(title, style: PlengoType.rowTitle.copyWith(fontSize: 14, color: PlengoColors.ink)),
                if (caption != null) Text(caption!, style: PlengoType.caption.copyWith(color: hue.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card-coloured panel at the foot of Browse and Study (top radius 28).
class BottomPanel extends StatelessWidget {
  const BottomPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
        border: s.isDark ? Border(top: BorderSide(color: s.line)) : null,
        boxShadow: s.isDark ? null : const [BoxShadow(color: Color(0x0F3C2D0A), offset: Offset(0, -6), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A list row whose trailing buttons stay separate for screen readers (a [ListRow] merges its whole
/// content into one node): the leading tile and texts are one button, [trailing] follow it.
class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.title,
    this.caption,
    this.leading,
    this.onTap,
    this.trailing = const [],
    this.maxTitleLines = 2,
  });

  final String title;
  final String? caption;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<Widget> trailing;
  final int maxTitleLines;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(PlengoRadius.row);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: r,
        border: s.isDark ? Border.all(color: s.line) : null,
        boxShadow: s.isDark ? null : [BoxShadow(color: s.line, offset: const Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: onTap != null,
                container: true,
                child: MergeSemantics(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: PlengoSpace.row),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
                          child: Row(
                            children: [
                              if (leading != null) ...[leading!, const SizedBox(width: 12)],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: maxTitleLines,
                                      overflow: TextOverflow.ellipsis,
                                      style: PlengoType.rowTitle.copyWith(color: s.ink),
                                    ),
                                    if (caption != null)
                                      Text(caption!, style: PlengoType.caption.copyWith(color: s.mute)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ...trailing,
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
