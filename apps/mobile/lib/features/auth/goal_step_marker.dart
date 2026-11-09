import '../../app/redesign_flags.dart';
import '../../core/db/app_database.dart';

/// Local marker for the daily-goal step (V-Goal, DECISIONS #17 `newDailyGoalStep`).
///
/// Set on this device when an email verification succeeds; the first successful login after it opens
/// the goal step instead of Home and clears the marker, so the step is shown once. Logout wipes it with
/// the rest of the local data. Nothing is sent to the server.
abstract final class GoalStepMarker {
  static const key = 'onboarding.goal_pending';

  static Future<void> mark(AppDatabase db) async {
    if (RedesignFlags.newDailyGoalStep) await db.setValue(key, '1');
  }

  static Future<bool> isPending(AppDatabase db) async =>
      RedesignFlags.newDailyGoalStep && await db.getValue(key) == '1';

  static Future<void> clear(AppDatabase db) => db.setValue(key, '0');
}
