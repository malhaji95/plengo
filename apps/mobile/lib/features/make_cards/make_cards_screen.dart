import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/coming_soon.dart';

// Placeholders for اصنع بطاقاتك الخاصة (v3 §7) at [Routes.makeCards] and [Routes.makeCardsGroups]
// (`?subjectId=`); the make-cards feature replaces them. Until then they link to the student's decks.

class MakeCardsScreen extends StatelessWidget {
  const MakeCardsScreen({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonScaffold(
    title: 'اصنع بطاقاتك الخاصة',
    mainPlace: true,
    icon: Icons.add_card_rounded,
    hue: PlengoColors.pink,
    actionLabel: 'بطاقاتي',
    onAction: () => context.go(Routes.myDecks),
  );
}

/// مجموعاتي: the student's own groups, optionally for one subject.
class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => ComingSoonScaffold(
    title: 'مجموعاتي',
    icon: Icons.collections_bookmark_rounded,
    hue: PlengoColors.pink,
    actionLabel: 'بطاقاتي',
    onAction: () => context.go(Routes.myDecks),
  );
}
