import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import 'card_templates.dart';

/// The subjects as a horizontal row of tiles (v3 §7): an icon tile in the subject's hue and the name;
/// the chosen one has a ring in its hue and a check.
class SubjectCarousel extends StatelessWidget {
  const SubjectCarousel({super.key, required this.subjects, required this.selected, required this.onSelected});

  final List<CatalogSubject> subjects;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('makeCards.subjects'),
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, sub) in subjects.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          _SubjectTile(subject: sub, selected: sub.id == selected, onTap: () => onSelected(sub.id)),
        ],
      ],
    ),
  );
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject, required this.selected, required this.onTap});

  final CatalogSubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = subjectHue(subject.id);
    final r = BorderRadius.circular(PlengoRadius.row);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: subject.nameAr,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: Key('makeCards.subject.${subject.id}'),
        color: s.isDark ? Color.alphaBlend(hue.base.withValues(alpha: 0.14), s.card) : hue.soft,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(color: selected ? hueBorder(context, hue) : Colors.transparent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SubjectIconTile(icon: Icons.menu_book_rounded, hue: hue, size: 44),
                      if (selected)
                        PositionedDirectional(
                          bottom: -6,
                          end: -6,
                          child: Container(
                            decoration: BoxDecoration(color: s.card, shape: BoxShape.circle),
                            child: Icon(Icons.check_circle_rounded, size: 20, color: hueBorder(context, hue)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subject.nameAr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.chip.copyWith(color: s.ink, height: 1.4),
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

/// A ring or check in a hue that stands out on both themes.
Color hueBorder(BuildContext context, PlengoHue hue) => context.surface.isDark ? hue.base : hue.ink;

/// The template grid (v3 §7): two columns of empty frames with a radio dot under each.
class TemplatePicker extends ConsumerWidget {
  const TemplatePicker({super.key, required this.templates, required this.selected, required this.onSelected});

  final List<CardTemplate> templates;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
    child: LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 560 ? 3 : 2;
        const gap = 12.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in templates)
              SizedBox(
                width: width,
                child: _TemplateTile(template: t, selected: t.key == selected, onTap: () => onSelected(t.key)),
              ),
          ],
        );
      },
    ),
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.selected, required this.onTap});

  final CardTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(18);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: 'قالب ${template.nameAr}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: Key('makeCards.template.${template.key}'),
        borderRadius: r,
        onTap: onTap,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: selected ? s.action : Colors.transparent, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1.45,
                    child: TemplateFrame(templateKey: template.key, compact: true, child: const SizedBox.expand()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: selected ? s.action : s.mute,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    template.nameAr,
                    overflow: TextOverflow.ellipsis,
                    style: PlengoType.chip.copyWith(color: s.ink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
