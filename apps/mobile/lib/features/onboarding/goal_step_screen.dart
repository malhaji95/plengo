import 'package:flutter/material.dart';

import '../../shared/ui/ui.dart';

/// The daily-goal step after email verification (V-Goal, flag `RedesignFlags.newDailyGoalStep`).
///
/// Placeholder: the route exists so later work does not touch the router; nothing navigates here yet.
class GoalStepScreen extends StatelessWidget {
  const GoalStepScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const PlengoBackButton(), leadingWidth: kPlengoLeadingWidth),
    body: const PlengoEmptyState(
      icon: Icons.flag_rounded,
      hue: PlengoColors.green,
      title: 'الهدف اليومي',
      message: 'هذه الخطوة قادمة قريباً.',
    ),
  );
}
