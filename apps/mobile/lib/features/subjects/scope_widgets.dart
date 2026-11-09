import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/ui/ui.dart';
import '../learning/scope_learning.dart';

/// The blue header of a subject or track page (V-Subject): back and download buttons, a large title,
/// the progress counts «الأسئلة 140/480 · …» and a yellow completion ring. Content below it sits on a
/// rounded panel that overlaps the header ([ScopePage]).
class ScopeHeader extends ConsumerWidget {
  const ScopeHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.subjectId,
    this.teacherTrackId,
    this.onDownload,
    this.downloadLabel = 'تحميل المادة للاستخدام دون اتصال',
  });

  final String title;
  final String? subtitle;
  final String subjectId;
  final String? teacherTrackId;

  /// Shows the download button (mobile only); usually scrolls to the download tile.
  final VoidCallback? onDownload;
  final String downloadLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider((subjectId: subjectId, teacherTrackId: teacherTrackId))).value;
    final counts = p == null
        ? ''
        : [
            if (p.questionsTotal > 0) 'الأسئلة ${p.questionsAttempted}/${p.questionsTotal}',
            if (p.quizzesTotal > 0) 'الاختبارات ${p.quizzesCompleted}/${p.quizzesTotal}',
            if (p.flashcardsTotal > 0) 'البطاقات ${p.flashcardsStudied}/${p.flashcardsTotal}',
          ].join(' · ');
    const white90 = Color(0xE6FFFFFF);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRect(
        child: ColoredBox(
          color: PlengoColors.blue.base,
          child: Stack(
            children: [
              const PositionedDirectional(top: -60, end: -60, child: _Blob(180, PlengoColors.heroBlob)),
              PositionedDirectional(top: 18, end: 76, child: _Blob(28, PlengoColors.yellow.base)),
              PositionedDirectional(top: 52, end: 116, child: _Blob(16, PlengoColors.pink.base)),
              Padding(
                padding: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top, bottom: 26 + 18),
                child: ContentWidthBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 4),
                        child: Row(
                          children: [
                            _HeaderButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'رجوع',
                              onPressed: () => Navigator.maybePop(context).then((popped) {
                                if (!popped && context.mounted) context.go(Routes.subjects);
                              }),
                            ),
                            const Spacer(),
                            if (onDownload != null)
                              _HeaderButton(
                                icon: Icons.download_rounded,
                                tooltip: downloadLabel,
                                onPressed: onDownload!,
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 2, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(title, style: PlengoType.title.copyWith(color: Colors.white)),
                                  ),
                                  if (subtitle != null)
                                    Text(subtitle!, style: PlengoType.sub.copyWith(color: white90, height: 1.6)),
                                  if (counts.isNotEmpty)
                                    Text(
                                      counts,
                                      key: const Key('scope.counts'),
                                      style: PlengoType.caption.copyWith(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.9,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (p != null) ...[
                              const SizedBox(width: 16),
                              ProgressRing(
                                key: const Key('completion'),
                                value: p.completionPercent / 100,
                                label: percent(p.completionPercent),
                                size: 78,
                                strokeWidth: 8,
                                color: PlengoColors.yellow.base,
                                trackColor: Colors.white.withValues(alpha: 0.25),
                                labelStyle: const TextStyle(
                                  fontFamily: PlengoType.family,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                semanticsLabel: 'تقدّمي ${percent(p.completionPercent)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(PlengoRadius.iconButton),
    ),
    child: PlengoIconButton(icon: icon, tooltip: tooltip, soft: false, color: Colors.white, onPressed: onPressed),
  );
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}

/// Centres [child] at most [PlengoSpace.contentMaxWide] wide (wide screens).
class ContentWidthBox extends StatelessWidget {
  const ContentWidthBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
      child: child,
    ),
  );
}

/// A scope page: the [header] on top, then [children] on the background panel with a 24 radius that
/// overlaps the header by 18 (V-Subject).
class ScopePage extends StatelessWidget {
  const ScopePage({super.key, required this.header, required this.children, this.controller});

  final Widget header;
  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Scaffold(
      backgroundColor: s.background,
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Transform.translate(
              offset: const Offset(0, -18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: s.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ContentWidthBox(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 16, PlengoSpace.screen, 28),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
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

/// «N» or «N · k مجاني» under a shortcut.
String shortcutCount(ContentCount c) => c.free > 0 ? '${c.total} · ${c.free} مجاني' : '${c.total}';

/// The row of four shortcuts on a subject or track page: الاختبارات / تدريب عشوائي (remote flag) /
/// البطاقات / بنك الأسئلة, each with «N · k مجاني». Shortcuts without content are hidden.
class ScopeShortcuts extends ConsumerWidget {
  const ScopeShortcuts({
    super.key,
    required this.subjectId,
    this.teacherTrackId,
    required this.quizCount,
    required this.questionCount,
    required this.deckCount,
    required this.quizzesPath,
    required this.decksPath,
    required this.questionsPath,
    this.decksLabel = 'البطاقات',
    this.questionsLabel = 'بنك الأسئلة',
  });

  final String subjectId;
  final String? teacherTrackId;
  final ContentCount quizCount;
  final ContentCount questionCount;
  final ContentCount deckCount;
  final String quizzesPath;
  final String decksPath;
  final String questionsPath;
  final String decksLabel;
  final String questionsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomEnabled = ref.watch(remoteConfigProvider).value?.features.randomPractice ?? true;
    final items = <Widget>[
      if (quizCount.total > 0)
        _Shortcut(
          icon: Icons.assignment_rounded,
          hue: PlengoColors.blue,
          label: 'الاختبارات',
          count: shortcutCount(quizCount),
          spoken: quizCountLabel(quizCount.total),
          onTap: () => context.go(quizzesPath),
        ),
      if (randomEnabled && questionCount.total > 0)
        _Shortcut(
          icon: Icons.shuffle_rounded,
          hue: PlengoColors.orange,
          label: 'تدريب عشوائي',
          count: '${questionCount.total}',
          spoken: 'اختر الوحدة والنوع وعدد الأسئلة',
          onTap: () => context.push(
            Uri(
              path: Routes.randomPractice,
              queryParameters: {'subjectId': subjectId, 'teacherTrackId': ?teacherTrackId},
            ).toString(),
          ),
        ),
      if (deckCount.total > 0)
        _Shortcut(
          icon: Icons.style_rounded,
          hue: PlengoColors.pink,
          label: decksLabel,
          count: shortcutCount(deckCount),
          spoken: deckCountLabel(deckCount),
          onTap: () => context.go(decksPath),
        ),
      if (questionCount.total > 0)
        _Shortcut(
          icon: Icons.quiz_rounded,
          hue: PlengoColors.green,
          label: questionsLabel,
          count: shortcutCount(questionCount),
          spoken: '${questionCount.total} سؤال',
          onTap: () => context.go(questionsPath),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, item) in items.indexed) ...[if (i > 0) const SizedBox(width: 4), Expanded(child: item)],
        // Keep tiles the same width when some are hidden.
        for (var i = items.length; i < 4; i++) ...[const SizedBox(width: 4), const Expanded(child: SizedBox())],
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.hue,
    required this.label,
    required this.count,
    required this.spoken,
    required this.onTap,
  });

  final IconData icon;
  final PlengoHue hue;
  final String label;
  final String count;
  final String spoken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      button: true,
      label: '$label، $spoken',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(PlengoRadius.row),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: PlengoSpace.minTouch),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 4, horizontal: 2),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: hue.soft, borderRadius: BorderRadius.circular(18)),
                    child: Icon(icon, color: hue.ink, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: PlengoType.chip.copyWith(color: s.ink, height: 1.4),
                  ),
                  Text(
                    count,
                    textAlign: TextAlign.center,
                    style: PlengoType.caption.copyWith(color: s.mute, fontSize: 11, height: 1.4),
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

/// «متاح» (green, open lock) or «مقفل» (red, lock): never colour alone (spec §4).
class AccessChip extends StatelessWidget {
  const AccessChip({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) => open
      ? const PlengoChip(label: 'متاح', hue: PlengoColors.green, icon: Icons.lock_open_rounded)
      : const LockedChip();
}

/// The red «مقفل» chip with a lock icon (locked subjects, decks, quizzes, questions).
class LockedChip extends StatelessWidget {
  const LockedChip({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlengoChip(label: 'مقفل', hue: PlengoColors.red, icon: Icons.lock_rounded);
}
