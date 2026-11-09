/// Switches for the redesign v2 behaviours the owner has not confirmed yet (docs/redesign/DECISIONS.md #17,
/// CLAUDE_CODE_PROMPT.md Phase 4). All default on; set one to `false` to fall back to the previous behaviour.
///
/// - [newDailyGoalStep]: the daily-goal step after email verification (V-Goal).
/// - [newStreakMoment]: the streak screen once per day after the first finished activity (V-Streak).
/// - [learningPath]: the learning-path layout on the subject page; off = the restyled units accordion.
/// - [homeOrderV2]: Continue + Today first on Home; off = countdown → banners → Today → mistakes → continue →
///   my subjects → free content → teachers.
///
/// These are compile-time constants, never remote config.
abstract final class RedesignFlags {
  static const newDailyGoalStep = true;
  static const newStreakMoment = true;
  static const learningPath = true;
  static const homeOrderV2 = true;
}
