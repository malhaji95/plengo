import 'package:flutter/material.dart';

import 'buttons.dart';
import 'tokens.dart';

enum AnswerState {
  /// Not chosen, not checked.
  normal,

  /// The student's choice before checking (blue).
  selected,

  /// The right answer after checking (green, «✓ صحيحة»).
  correct,

  /// The student's wrong choice after checking (red, «✗ إجابتك»).
  wrong,

  /// Every other option after checking (60% opacity).
  dimmed,
}

/// An answer option tile (spec §4): min 62, radius 18, 2 px border, 3 px bottom shadow, letter badge at
/// the start. State is never colour alone: correct/wrong carry a ✓/✗ tag, selected a filled badge.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.index,
    required this.text,
    this.state = AnswerState.normal,
    this.onTap,
    this.child,
    this.ltr = false,
  });

  /// Arabic option letters in order.
  static const letters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح'];

  static String letterFor(int index) => index < letters.length ? letters[index] : '${index + 1}';

  static const correctTag = '✓ صحيحة';
  static const wrongTag = '✗ إجابتك';

  /// Position, for the letter badge (0 = أ).
  final int index;

  /// The option text (also its spoken label).
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;

  /// Replaces the text widget (e.g. an image or rich formula); [text] is still spoken.
  final Widget? child;

  /// Lays the text out left-to-right (formulas, Latin answers).
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final (border, bg, shadow, badgeBg, badgeFg, fg) = switch (state) {
      AnswerState.normal || AnswerState.dimmed => (s.line, s.card, s.line, s.track, s.ink, s.ink),
      AnswerState.selected => (
        PlengoColors.blue.base,
        PlengoColors.blue.soft,
        PlengoColors.blue.base,
        PlengoColors.blue.base,
        Colors.white,
        PlengoColors.ink,
      ),
      AnswerState.correct => (
        PlengoColors.green.base,
        PlengoColors.green.soft,
        PlengoColors.green.base,
        PlengoColors.green.base,
        PlengoColors.ink,
        PlengoColors.ink,
      ),
      AnswerState.wrong => (
        PlengoColors.red.base,
        PlengoColors.red.soft,
        PlengoColors.red.base,
        PlengoColors.redStrong,
        Colors.white,
        PlengoColors.ink,
      ),
    };
    final tag = switch (state) {
      AnswerState.correct => correctTag,
      AnswerState.wrong => wrongTag,
      _ => null,
    };
    final tagColor = state == AnswerState.correct ? PlengoColors.green.ink : PlengoColors.red.ink;
    final r = BorderRadius.circular(PlengoRadius.option);
    final letter = letterFor(index);

    final tile = AnimatedContainer(
      duration: PlengoMotion.of(context, PlengoMotion.feedback),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: r,
        border: Border.all(color: border, width: 2),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 3))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PlengoSpace.option - 4),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(11)),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                      child:
                          child ??
                          Text(text, textDirection: ltr ? TextDirection.ltr : null, textAlign: TextAlign.start),
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      tag,
                      style: TextStyle(
                        fontFamily: PlengoType.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tagColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final spoken = [
      '$letter. $text',
      if (tag == correctTag) 'الإجابة الصحيحة',
      if (tag == wrongTag) 'إجابتك، خاطئة',
    ].join('، ');
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: state == AnswerState.selected || state == AnswerState.wrong,
      button: onTap != null,
      enabled: onTap != null,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        // Room for the 3 px bottom shadow so neighbours never overlap it.
        padding: const EdgeInsets.only(bottom: 3),
        child: AnimatedOpacity(
          opacity: state == AnswerState.dimmed ? 0.6 : 1,
          duration: PlengoMotion.of(context, PlengoMotion.feedback),
          child: tile,
        ),
      ),
    );
  }
}

/// The bottom feedback panel after checking an answer (spec §4). Slides up over 200 ms.
///
/// Correct: green-soft, a green ✓ circle, «أحسنت!», the explanation and a green «متابعة» button.
/// Wrong: red-soft, a red ✗ circle, «ليست الإجابة الصحيحة», the correct answer line, the explanation,
/// the mistakes note and a red «فهمت، متابعة» button. [onReport] adds the report flag button.
class FeedbackPanel extends StatefulWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.onContinue,
    this.title,
    this.correctAnswer,
    this.explanation,
    this.note,
    this.actionLabel,
    this.onReport,
    this.reportAction,
    this.extra,
  });

  static const correctTitle = 'أحسنت!';
  static const wrongTitle = 'ليست الإجابة الصحيحة';
  static const mistakesNote = 'أضفناه إلى «مراجعة الأخطاء» لتتدرّب عليه لاحقاً.';

  final bool correct;
  final VoidCallback? onContinue;

  /// Defaults to [correctTitle] / [wrongTitle].
  final String? title;

  /// Wrong only: shown as «الإجابة الصحيحة: …».
  final Widget? correctAnswer;
  final Widget? explanation;

  /// Wrong only: a small line under the explanation, e.g. [mistakesNote]. Hidden when null.
  final String? note;

  /// Defaults to «متابعة» / «فهمت، متابعة».
  final String? actionLabel;

  /// Shows a flag icon button («إبلاغ عن مشكلة») in the panel header.
  final VoidCallback? onReport;

  /// Replaces the default report button.
  final Widget? reportAction;

  /// Extra content above the button (e.g. the in-session streak chip).
  final Widget? extra;

  @override
  State<FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: PlengoMotion.feedback);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PlengoMotion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.correct;
    final hue = ok ? PlengoColors.green : PlengoColors.red;
    final title = widget.title ?? (ok ? FeedbackPanel.correctTitle : FeedbackPanel.wrongTitle);
    final report =
        widget.reportAction ??
        (widget.onReport == null
            ? null
            : PlengoIconButton(
                icon: Icons.flag_outlined,
                tooltip: 'إبلاغ عن مشكلة',
                soft: false,
                color: hue.ink,
                onPressed: widget.onReport,
              ));
    final body = <Widget>[
      if (!ok && widget.correctAnswer != null)
        DefaultTextStyle.merge(
          style: TextStyle(fontFamily: PlengoType.family, fontSize: 15, fontWeight: FontWeight.w700, color: hue.ink),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الإجابة الصحيحة: '),
              Expanded(child: widget.correctAnswer!),
            ],
          ),
        ),
      if (widget.explanation != null)
        DefaultTextStyle.merge(
          style: PlengoType.sub.copyWith(color: PlengoColors.ink),
          child: widget.explanation!,
        ),
      if (!ok && widget.note != null)
        Text(widget.note!, style: PlengoType.caption.copyWith(color: const Color(0xFF5E3A3A))),
      ?widget.extra,
    ];
    final panel = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hue.soft,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: ok ? hue.base : PlengoColors.redStrong, shape: BoxShape.circle),
                      child: Icon(
                        ok ? Icons.check_rounded : Icons.close_rounded,
                        color: ok ? PlengoColors.ink : Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: PlengoType.family,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: hue.ink,
                        ),
                      ),
                    ),
                  ),
                  ?report,
                ],
              ),
              if (body.isNotEmpty)
                ConstrainedBox(
                  // Long explanations scroll inside the panel; the button stays in reach.
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, w) in body.indexed) ...[if (i > 0) const SizedBox(height: 8), w],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              PlengoButton(
                label: widget.actionLabel ?? (ok ? 'متابعة' : 'فهمت، متابعة'),
                variant: ok ? PlengoButtonVariant.success : PlengoButtonVariant.danger,
                onPressed: widget.onContinue,
              ),
            ],
          ),
        ),
      ),
    );
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
      child: panel,
    );
  }
}
