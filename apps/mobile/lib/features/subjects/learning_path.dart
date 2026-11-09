import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../flashcards/decks_screen.dart' show cardCountLabel;
import '../learning/scope_learning.dart' show quizCountLabel;
import '../questions/question_providers.dart' show questionCountLabel;
import '../quizzes/attempt_widgets.dart' show humanDuration;

/// The state of one lesson node on the learning path (DECISIONS #7).
enum PathNodeState { done, current, upcoming }

/// The lesson of [items] (the resume list, newest first) the student was last working on in this
/// subject's general content, if any.
String? resumeLessonId(String subjectId, List<ResumeItem>? items) => items
    ?.where((r) => r.subjectId == subjectId && r.teacherTrackId == null && r.lessonId != null)
    .firstOrNull
    ?.lessonId;

/// Node states from the per-lesson completion (DECISIONS #7): 100 % is done; the current node is the
/// resume item's lesson (when it is not done yet), else the first lesson below 100 %, in [lessons]'
/// order; every other lesson is upcoming. Lessons without progress count as 0 %.
Map<String, PathNodeState> pathNodeStates({
  required List<Lesson> lessons,
  required Map<String, int> percents,
  String? resumeLessonId,
}) {
  bool done(String id) => (percents[id] ?? 0) >= 100;
  final ids = lessons.map((l) => l.id).toList();
  final current = resumeLessonId != null && ids.contains(resumeLessonId) && !done(resumeLessonId)
      ? resumeLessonId
      : ids.where((id) => !done(id)).firstOrNull;
  return {
    for (final id in ids)
      id: done(id)
          ? PathNodeState.done
          : id == current
          ? PathNodeState.current
          : PathNodeState.upcoming,
  };
}

/// A unit is complete when it has lessons and all of them are done, or its own progress says 100 %.
bool unitComplete(UnitWithLessons unit, Map<String, PathNodeState> states, int? unitPercent) =>
    (unitPercent ?? 0) >= 100 ||
    (unit.lessons.isNotEmpty && unit.lessons.every((l) => states[l.id] == PathNodeState.done));

/// Arabic count agreement for units: وحدة واحدة، وحدتان، 3–10 وحدات، 11+ وحدة.
String unitCountLabel(int n) => switch (n) {
  1 => 'وحدة واحدة',
  2 => 'وحدتان',
  >= 3 && <= 10 => '$n وحدات',
  _ => '$n وحدة',
};

/// «وحدة واحدة مكتملة» / «الوحدتان مكتملتان» / «3 وحدات مكتملة».
String completedUnitsLabel(int n) => switch (n) {
  1 => 'وحدة واحدة مكتملة',
  2 => 'الوحدتان مكتملتان',
  _ => '${unitCountLabel(n)} مكتملة',
};

/// The meta line of a lesson node's card, from its progress.
String lessonMeta(LessonProgress? p) {
  if (p == null) return 'لم تبدأ بعد';
  return [
    if (p.questionsTotal > 0) questionCountLabel(p.questionsTotal),
    if (p.flashcardsTotal > 0) cardCountLabel(p.flashcardsTotal),
    if (p.quizzesTotal > 0) quizCountLabel(p.quizzesTotal),
    p.completionPercent > 0 ? 'أنجزت ${percent(p.completionPercent)}' : 'لم تبدأ بعد',
  ].join(' · ');
}

String quizMeta(StudentQuiz q) => [
  questionCountLabel(q.totalCount),
  if (q.timeLimitSeconds != null) humanDuration(q.timeLimitSeconds! * 1000),
  if (q.passingScorePercent != null) 'النجاح ${percent(q.passingScorePercent!)}',
  if (q.bestScorePercent != null) 'أفضل نتيجة ${percent(q.bestScorePercent!)}',
  if (q.locked) 'مقفل',
].join(' · ');

/// One unit drawn as a zig-zag path (V-Subject): lesson nodes, then the unit-quiz node. Tapping a node
/// opens its card under it; tapping again closes it.
class LessonPath extends StatefulWidget {
  const LessonPath({
    super.key,
    required this.subjectId,
    required this.unitTitle,
    required this.lessons,
    required this.states,
    required this.progress,
    this.quiz,
  });

  final String subjectId;
  final String unitTitle;
  final List<Lesson> lessons;
  final Map<String, PathNodeState> states;
  final Map<String, LessonProgress> progress;
  final StudentQuiz? quiz;

  @override
  State<LessonPath> createState() => _LessonPathState();
}

class _LessonPathState extends State<LessonPath> {
  /// The node whose card is open: a lesson id, `quiz`, or null.
  String? _open;

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, box) {
        final amp = (box.maxWidth / 2 - 84).clamp(0.0, 90.0);
        double offset(int i) => math.sin(i * 0.9) * amp * (rtl ? -1 : 1);
        final nodes = <Widget>[];
        for (final (i, lesson) in widget.lessons.indexed) {
          final state = widget.states[lesson.id] ?? PathNodeState.upcoming;
          final p = widget.progress[lesson.id];
          final kind = switch (state) {
            PathNodeState.done => _NodeKind.done,
            PathNodeState.current => _NodeKind.current,
            PathNodeState.upcoming => _NodeKind.upcoming,
          };
          nodes.add(
            _PathItem(
              key: Key('path.${lesson.id}'),
              kind: kind,
              title: lesson.titleAr,
              meta: lessonMeta(p),
              dx: offset(i),
              open: _open == lesson.id,
              onTap: () => _toggle(lesson.id),
              actionLabel: switch (state) {
                PathNodeState.done => 'تدرّب مجدداً',
                PathNodeState.current => (p?.completionPercent ?? 0) > 0 ? 'تابع الدرس' : 'ابدأ الدرس',
                PathNodeState.upcoming => 'ابدأ الدرس',
              },
              onAction: () => context.go(
                (p?.questionsTotal ?? 0) > 0
                    ? '${Routes.subjects}/${widget.subjectId}/questions?lessonId=${lesson.id}'
                    : '${Routes.subjects}/${widget.subjectId}/lessons/${lesson.id}',
              ),
              onDetails: () => context.go('${Routes.subjects}/${widget.subjectId}/lessons/${lesson.id}'),
            ),
          );
        }
        final quiz = widget.quiz;
        if (quiz != null) {
          nodes.add(
            _PathItem(
              key: Key('path.quiz.${quiz.id}'),
              kind: _NodeKind.quiz,
              title: quiz.titleAr,
              meta: quizMeta(quiz),
              dx: offset(widget.lessons.length),
              open: _open == 'quiz',
              locked: quiz.locked,
              onTap: () => _toggle('quiz'),
              actionLabel: 'ابدأ اختبار الوحدة',
              onAction: () => context.go('${Routes.quizzes}/${quiz.id}'),
            ),
          );
        }
        return Semantics(
          container: true,
          label: 'دروس ${widget.unitTitle}',
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: 14, bottom: 6),
            child: Column(children: nodes),
          ),
        );
      },
    );
  }
}

enum _NodeKind { done, current, upcoming, quiz }

class _PathItem extends StatelessWidget {
  const _PathItem({
    super.key,
    required this.kind,
    required this.title,
    required this.meta,
    required this.dx,
    required this.open,
    required this.onTap,
    required this.actionLabel,
    required this.onAction,
    this.onDetails,
    this.locked = false,
  });

  final _NodeKind kind;
  final String title;
  final String meta;
  final double dx;
  final bool open;
  final VoidCallback onTap;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDetails;
  final bool locked;

  String get _stateLabel => switch (kind) {
    _NodeKind.done => 'مكتمل',
    _NodeKind.current => 'الحالي',
    _NodeKind.upcoming => 'لم يبدأ',
    _NodeKind.quiz => locked ? 'اختبار الوحدة، مقفل' : 'اختبار الوحدة',
  };

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final current = kind == _NodeKind.current;
    // Full width, so the node shifted by [dx] stays inside this box and can be hit.
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: double.infinity),
          Transform.translate(
            offset: Offset(dx, 0),
            child: Column(
              children: [
                if (current)
                  ExcludeSemantics(
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(bottom: 8),
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: s.card,
                        border: Border.all(color: s.action, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('ابدأ هنا', style: PlengoType.chip.copyWith(color: s.action, fontSize: 13)),
                    ),
                  ),
                Semantics(
                  button: true,
                  expanded: open,
                  label: '$title، $_stateLabel',
                  excludeSemantics: true,
                  onTap: onTap,
                  child: _Node(kind: kind, locked: locked, onTap: onTap),
                ),
                const SizedBox(height: 6),
                ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: PlengoType.chip.copyWith(color: s.ink, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (open)
            _NodeCard(
              kind: kind,
              title: title,
              meta: meta,
              actionLabel: actionLabel,
              onAction: onAction,
              onDetails: onDetails,
            ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.kind, required this.locked, required this.onTap});

  final _NodeKind kind;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final size = kind == _NodeKind.current ? PlengoSpace.pathNodeCurrent : PlengoSpace.pathNode;
    final (Color fill, Color fg, Color shadow, IconData icon, Border? border) = switch (kind) {
      _NodeKind.done => (
        PlengoColors.yellow.base,
        PlengoColors.ink,
        PlengoColors.yellow.shadow,
        Icons.check_rounded,
        null,
      ),
      _NodeKind.current => (
        PlengoColors.blue.base,
        Colors.white,
        PlengoColors.blue.shadow,
        Icons.play_arrow_rounded,
        null,
      ),
      _NodeKind.upcoming => (
        s.track,
        s.mute,
        s.isDark ? s.line : const Color(0xFFD9D3C7),
        Icons.menu_book_rounded,
        null,
      ),
      _NodeKind.quiz => (
        PlengoColors.orange.soft,
        PlengoColors.orange.ink,
        const Color(0xFFF0C796),
        Icons.emoji_events_rounded,
        Border.all(color: PlengoColors.orange.base, width: 3),
      ),
    };
    return SizedBox(
      width: size + (kind == _NodeKind.current ? 16 : 0),
      height: size + (kind == _NodeKind.current ? 16 : 6),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: border,
                boxShadow: [
                  BoxShadow(color: shadow, offset: const Offset(0, 6)),
                  if (kind == _NodeKind.current) BoxShadow(color: s.actionSoft, spreadRadius: 8),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Icon(icon, color: fg, size: kind == _NodeKind.current ? 40 : 34),
                ),
              ),
            ),
            if (locked)
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: PlengoColors.red.soft,
                    shape: BoxShape.circle,
                    border: Border.all(color: s.background, width: 2),
                  ),
                  child: Icon(Icons.lock_rounded, size: 14, color: PlengoColors.red.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The card anchored under a tapped node: title, meta, the primary action and «عرض الدرس بالتفصيل».
class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.kind,
    required this.title,
    required this.meta,
    required this.actionLabel,
    required this.onAction,
    this.onDetails,
  });

  final _NodeKind kind;
  final String title;
  final String meta;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    // Fills and their text: yellow/orange take dark ink; blue and the grey take white.
    final (Color bg, Color fg, Color actionFg) = switch (kind) {
      _NodeKind.done => (PlengoColors.yellow.base, PlengoColors.ink, PlengoColors.ink),
      _NodeKind.current => (PlengoColors.blue.base, Colors.white, PlengoColors.blue.base),
      _NodeKind.upcoming => (const Color(0xFF5E5A52), Colors.white, PlengoColors.ink),
      _NodeKind.quiz => (PlengoColors.orange.base, PlengoColors.ink, PlengoColors.orange.ink),
    };
    final r = BorderRadius.circular(PlengoRadius.row);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        margin: const EdgeInsetsDirectional.only(top: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsetsDirectional.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: r,
          boxShadow: const [BoxShadow(color: Color(0x26000000), offset: Offset(0, 8), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: PlengoType.rowTitle.copyWith(color: fg, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: PlengoType.caption.copyWith(color: fg),
            ),
            const SizedBox(height: 10),
            _WhiteButton(label: actionLabel, color: actionFg, onPressed: onAction),
            if (onDetails != null)
              Semantics(
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(PlengoRadius.buttonSmall),
                  onTap: onDetails,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: PlengoSpace.minTouch),
                    child: Center(
                      child: Text(
                        'عرض الدرس بالتفصيل',
                        textAlign: TextAlign.center,
                        style: PlengoType.chip.copyWith(color: fg, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.color, required this.onPressed});

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(PlengoRadius.buttonSmall);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: r,
          boxShadow: const [BoxShadow(color: Color(0x2E000000), offset: Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: PlengoSpace.minTouch),
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: PlengoType.button.copyWith(color: color, fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
