import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/coming_soon.dart';

/// Placeholder for فلاش كاردز بلينغو (v3 §6) at [Routes.plengoCards] (`?subjectId=` narrows it to one
/// subject); the flashcards feature replaces it. Until then it links to the subject's decks, or to the
/// review tab.
class PlengoCardsScreen extends StatelessWidget {
  const PlengoCardsScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    final id = subjectId;
    return ComingSoonScaffold(
      title: 'فلاش كاردز بلينغو',
      mainPlace: id == null,
      icon: Icons.style_rounded,
      hue: PlengoColors.pink,
      actionLabel: id == null ? 'المراجعة' : 'بطاقات المادة',
      onAction: () => context.go(id == null ? Routes.review : '${Routes.subjects}/$id/decks'),
    );
  }
}
