import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/responsive.dart';
import '../home/home_providers.dart';
import '../home/notification_screens.dart';

/// The daily-goal step after email verification (V-Goal, flag `RedesignFlags.newDailyGoalStep`): the
/// goal list, the review-reminder switch (on by default, its time in Damascus time), «متابعة» to save
/// both and go Home, and «تخطي» to go Home without saving.
class GoalStepScreen extends ConsumerStatefulWidget {
  const GoalStepScreen({super.key});

  @override
  ConsumerState<GoalStepScreen> createState() => _GoalStepScreenState();
}

class _GoalStepScreenState extends ConsumerState<GoalStepScreen> {
  int _goal = 20;
  bool _reminder = true;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await ref.read(homeRepositoryProvider).setGoal(_goal);
      await ref.read(homeRepositoryProvider).setPreferences(reviewReminder: _reminder);
      ref.invalidate(homeProvider);
      ref.invalidate(dailyGoalProvider);
      ref.invalidate(notificationPreferencesProvider);
      if (mounted) context.go(Routes.home);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final time = ref.watch(notificationPreferencesProvider).value?.reminderTime;
    final green = PlengoColors.green;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: PlengoSpace.screen,
        title: Text('خطوة أخيرة', style: PlengoType.chip.copyWith(color: s.mute)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Center(
              child: PlengoButton(
                label: 'تخطي',
                variant: PlengoButtonVariant.ghost,
                size: PlengoButtonSize.small,
                onPressed: _saving ? null : () => context.go(Routes.home),
              ),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 24),
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: green.soft, shape: BoxShape.circle),
                    child: Icon(Icons.flag_rounded, size: 34, color: green.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text('ما هدفك اليومي؟', style: PlengoType.title.copyWith(fontSize: 22, color: s.ink)),
                      ),
                      Text(
                        'عدد البطاقات والإجابات كل يوم. يمكنك تغييره لاحقاً.',
                        style: PlengoType.sub.copyWith(color: s.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'الهدف اليومي',
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final p in dailyGoalPresets) ...[
                    RadioRow(
                      title: p.label,
                      caption: '${p.goal} عنصراً يومياً',
                      selected: _goal == p.goal,
                      onTap: () => setState(() => _goal = p.goal),
                      trailing: PlengoChip(label: goalMinutesLong(p.minutes), hue: PlengoColors.blue),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            PlengoCard(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
              radius: PlengoRadius.row,
              child: Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  secondary: const SubjectIconTile(
                    icon: Icons.alarm_rounded,
                    hue: PlengoColors.orange,
                    soft: true,
                    size: 40,
                  ),
                  title: const Text('ذكّرني بالمراجعة'),
                  subtitle: Text(time == null ? 'بتوقيت دمشق' : '\u2066$time\u2069 بتوقيت دمشق'),
                  value: _reminder,
                  onChanged: _saving ? null : (v) => setState(() => _reminder = v),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: PlengoButton(label: 'متابعة', busy: _saving, onPressed: _continue),
            ),
          ),
        ),
      ),
    );
  }
}
