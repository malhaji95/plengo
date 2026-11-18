import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/coming_soon.dart';

// Placeholders for تدرّب (v3 §5, §9); the practice feature replaces them. Routes: [Routes.practice],
// [Routes.practiceSetup] (`/practice/:subjectId`); [Routes.practiceDiagrams] is `features/diagrams`.

/// تدرّب: the student's subjects and «اختبارات بلينغو المخصصة».
class PracticeHomeScreen extends StatelessWidget {
  const PracticeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonScaffold(
    title: 'تدرّب',
    mainPlace: true,
    icon: Icons.fact_check_rounded,
    hue: PlengoColors.blue,
    actionLabel: 'المواد',
    onAction: () => context.go(Routes.subjects),
  );
}

/// Practice setup for one subject (units → lessons → categories → types → count). Until it is built
/// it offers the existing random practice of the subject.
class PracticeSetupScreen extends StatelessWidget {
  const PracticeSetupScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) => ComingSoonScaffold(
    title: 'تدريب',
    icon: Icons.fact_check_rounded,
    hue: PlengoColors.blue,
    message: 'إعداد التدريب حسب الدروس والتصنيفات قادم قريباً. يمكنك الآن التدرّب عشوائياً على أسئلة المادة.',
    actionLabel: 'تدريب عشوائي',
    onAction: () =>
        context.push(Uri(path: Routes.randomPractice, queryParameters: {'subjectId': subjectId}).toString()),
  );
}
