import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/redesign_flags.dart';
import '../../app/router.dart';
import '../../core/srs/scheduler.dart';
import 'home_providers.dart';

const _shownDayKey = 'streak.moment_day';

/// Opens the streak moment (V-Streak) once per business day, after the first finished activity
/// (a quiz result or a finished flashcard session). Call it where that activity's «متابعة» leaves
/// the flow; it returns at once when the flag is off, the moment was already shown today, or there
/// is no streak to celebrate (the streak counts days with the daily goal met).
Future<void> maybeShowStreakMoment(BuildContext context, WidgetRef ref) async {
  if (!RedesignFlags.newStreakMoment) return;
  final db = ref.read(databaseProvider);
  final today = '${businessDay(DateTime.now().millisecondsSinceEpoch)}';
  if (await db.getValue(_shownDayKey) == today) return;
  ref.invalidate(homeProvider);
  final int streak;
  try {
    streak = (await ref.read(homeProvider.future)).today.streak;
  } catch (_) {
    return; // Offline: no numbers to show; try again after the next activity.
  }
  if (streak <= 0) return;
  await db.setValue(_shownDayKey, today);
  if (context.mounted) await context.push(Routes.streak);
}
