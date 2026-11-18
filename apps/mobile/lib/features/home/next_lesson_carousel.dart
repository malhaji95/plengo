import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../my_subjects/my_subjects_providers.dart';
import 'auto_advance.dart';

/// Home «راجع الدرس التالي:» (v3 §2): circular lesson tiles (lesson name, subject, the subject's hue)
/// with the centre one large and a ▶ that opens the lesson page. It moves by itself every ~4 s (paused
/// while touched; never with reduced motion), with side arrows and dots. Data:
/// [nextLessonsProvider]. Nothing is shown while loading or when there is no next lesson.
class NextLessonCarousel extends ConsumerWidget {
  const NextLessonCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(nextLessonsProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return NextLessonCarouselView(items: items);
  }
}

class NextLessonCarouselView extends StatefulWidget {
  const NextLessonCarouselView({super.key, required this.items});

  final List<NextLessonItem> items;

  static const interval = Duration(seconds: 4);

  @override
  State<NextLessonCarouselView> createState() => NextLessonCarouselState();
}

class NextLessonCarouselState extends State<NextLessonCarouselView> with AutoAdvance {
  @override
  final pager = PageController(viewportFraction: 0.44);
  int _page = 0;

  @override
  int get pageCount => widget.items.length;

  @override
  Duration get autoAdvanceInterval => NextLessonCarouselView.interval;

  /// The tile in the centre.
  int get page => _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAutoAdvance();
  }

  @override
  void didUpdateWidget(NextLessonCarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      if (_page >= widget.items.length) _page = 0;
      syncAutoAdvance();
    }
  }

  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    final n = widget.items.length;
    pager.animateToPage(
      (i + n) % n,
      duration: PlengoMotion.of(context, const Duration(milliseconds: 350)),
      curve: Curves.easeInOut,
    );
  }

  void _open(NextLessonItem item) => context.go('${Routes.subjects}/${item.subjectId}/lessons/${item.lesson.id}');

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final items = widget.items;
    final n = items.length;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        key: const Key('home.nextLessons'),
        padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 8, 12),
        decoration: BoxDecoration(
          color: s.isDark ? s.card : PlengoColors.blue.soft,
          borderRadius: BorderRadius.circular(PlengoRadius.card),
          border: s.isDark ? Border.all(color: s.line) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.track_changes_rounded, color: PlengoColors.red.base, size: 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('راجع الدرس التالي:', style: PlengoType.section.copyWith(color: s.ink)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, box) {
                final tile = (box.maxWidth * 0.44).clamp(120.0, 190.0);
                return SizedBox(
                  // Room for the centre tile, its ▶ button and the larger text steps.
                  height: tile + 30 + 8 * scale,
                  child: Stack(
                    children: [
                      holdOnTouch(
                        PageView.builder(
                          key: const Key('home.nextLessons.pager'),
                          controller: pager,
                          itemCount: n,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) => AnimatedBuilder(
                            animation: pager,
                            builder: (context, child) {
                              final current = pager.hasClients && pager.position.haveDimensions
                                  ? pager.page ?? _page.toDouble()
                                  : _page.toDouble();
                              final t = (1 - (current - i).abs()).clamp(0.0, 1.0);
                              return Align(
                                alignment: Alignment.topCenter,
                                child: _LessonTile(
                                  item: items[i],
                                  size: tile * (0.76 + 0.24 * t),
                                  centre: i == _page,
                                  index: i,
                                  count: n,
                                  onTap: () => i == _page ? _open(items[i]) : _goTo(i),
                                  onPlay: () => _open(items[i]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (n > 1) ...[
                        PositionedDirectional(
                          start: 0,
                          top: tile / 2 - 24,
                          child: _Arrow(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'الدرس السابق',
                            onPressed: () => _goTo(_page - 1),
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          top: tile / 2 - 24,
                          child: _Arrow(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'الدرس التالي',
                            onPressed: () => _goTo(_page + 1),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (n > 1) ...[
              const SizedBox(height: 6),
              PageDots(count: n, index: _page, label: 'الدرس ${_page + 1} من $n'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: context.surface.isDark
          ? null
          : const [BoxShadow(color: Color(0x1F000000), offset: Offset(0, 3), blurRadius: 8)],
    ),
    child: PlengoIconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
  );
}

/// One lesson: a circle in the subject's soft hue with the lesson name and subject; the centre tile has
/// a yellow ring and the blue ▶.
class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.item,
    required this.size,
    required this.centre,
    required this.index,
    required this.count,
    required this.onTap,
    required this.onPlay,
  });

  final NextLessonItem item;
  final double size;
  final bool centre;
  final int index;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final hue = subjectHue(item.subjectId);
    final title = item.lesson.titleAr;
    return SizedBox(
      width: size,
      height: size + 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Semantics(
            button: true,
            label: '$title، ${item.subjectName}، ${index + 1} من $count',
            hint: centre ? 'افتح الدرس' : null,
            excludeSemantics: true,
            onTap: onTap,
            child: Material(
              color: hue.soft,
              shape: CircleBorder(
                side: centre ? BorderSide(color: PlengoColors.yellow.base, width: 5) : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox.square(
                  dimension: size,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(size * 0.14, size * 0.14, size * 0.14, size * 0.2),
                    // Long names and large text shrink rather than spill out of the circle.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: size * 0.72,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, color: hue.ink, size: size * 0.2),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink, height: 1.3),
                            ),
                            Text(
                              item.subjectName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PlengoType.caption.copyWith(color: hue.ink, fontWeight: FontWeight.w600),
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
          if (centre)
            Positioned(
              top: size - 24,
              child: Semantics(
                button: true,
                label: 'ابدأ الدرس: $title',
                excludeSemantics: true,
                onTap: onPlay,
                child: Material(
                  key: const Key('home.nextLessons.play'),
                  color: PlengoColors.blue.base,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPlay,
                    child: const SizedBox.square(
                      dimension: PlengoSpace.minTouch,
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page dots: the current one a wide yellow pill (v3 mockup), the rest small line-coloured dots. One
/// spoken [label] for the whole row.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index, required this.label, this.active});

  final int count;
  final int index;
  final String label;

  /// The current dot's colour (default brand yellow).
  final Color? active;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: PlengoMotion.of(context, PlengoMotion.press),
              width: i == index ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: i == index ? (active ?? PlengoColors.yellow.base) : s.line,
              ),
            ),
        ],
      ),
    );
  }
}
