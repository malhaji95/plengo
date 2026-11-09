import 'package:flutter/material.dart';

import '../../shared/ui/ui.dart';

/// The streak moment after the first finished activity of the day (V-Streak, flag
/// `RedesignFlags.newStreakMoment`).
///
/// Placeholder: the route exists so later work does not touch the router; nothing navigates here yet.
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const PlengoCloseButton(), leadingWidth: kPlengoLeadingWidth),
    body: const PlengoEmptyState(
      icon: Icons.local_fire_department_rounded,
      hue: PlengoColors.orange,
      title: 'أيام متتالية',
      message: 'هذه الشاشة قادمة قريباً.',
    ),
  );
}
