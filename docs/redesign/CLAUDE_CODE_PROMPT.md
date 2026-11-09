# Plengo — UI redesign implementation brief (for Claude Code)

You are working in the **Plengo** Flutter repository, an Arabic (RTL) study app for Syrian school and university students (Android, iOS, web). Your job is to **implement the approved visual redesign** described in `docs/redesign/`. It is a **UI-layer change**: keep all existing behaviour, APIs, data models, offline sync and permissions exactly as they are.

## 0. Files you were given (read them all before writing code)

| File | What it is |
|---|---|
| `docs/redesign/DESIGN_SPEC.md` | The source of truth: tokens, components, every screen's layout and states, interaction rules, accessibility, RTL. |
| `docs/redesign/tokens.json` | Machine-readable design tokens (colors, radii, spacing, type, shadows). |
| `docs/redesign/plengo_tokens.dart` | A starting point for the Dart token classes. Move or adapt it into the codebase's own structure. |
| `docs/redesign/screens/*.dc.html` | The HTML source of every designed screen. Each file is one 390 × 844 phone screen (the web one is 1024 × 768). Read the markup for layout, spacing, copy and colors. The `<script>` block at the bottom holds the screen's sample data and its interactive states. `{{name}}` are template holes filled by that script. `/_blob/...` URLs are the logo and font. Use the app's own `assets/brand/*` and `assets/fonts/MontserratArabic-*` instead. |
| `docs/redesign/screens/INDEX.md` | Maps each design screen to the existing Dart file it replaces. |

The live design canvas (clickable prototype) is linked in `docs/redesign/README.md`. If something in the HTML is unclear, ask the owner for a screenshot; do not guess.

## 1. Hard rules

1. **Do not change behaviour.** Do not change API calls, Riverpod providers' contracts, go_router paths, drift tables, offline/lease logic, SRS scheduling, attempt submission, auth, or analytics/Sentry. Re-skin and re-arrange widgets only. If a design needs data the app does not already expose, **stop and list it**. Do not invent endpoints or fields.
2. **Preserve every existing feature.** The redesign moves things but removes nothing. Check against the feature list in `DESIGN_SPEC.md` §9.
3. **Arabic RTL first.** Use `Directionality`/`EdgeInsetsDirectional`/`AlignmentDirectional` everywhere, not left/right. Wrap emails, codes, URLs and formulas in LTR isolation (the repo already has `shared/text/bidi.dart`; use it). Mirror directional icons (back, chevrons); never mirror the logo or non-directional icons. Use Western digits 0–9.
4. **One font:** `MontserratArabic` (weights 400/500/600/700, already bundled). No other font.
5. **Accessibility:** touch targets ≥ 48 dp; text contrast ≥ 4.5:1 (the palette in the spec already passes, so don't invent new color pairs); never use color alone for state (always add an icon and/or text: ✓/✗, lock + «مقفل», etc.); add semantics labels to icon-only buttons; respect the app's 3 font sizes (small / normal / large) and system text scaling without clipping.
6. **Themes:** light and dark both, from the same tokens (dark values are in the spec).
7. **Responsive:** below 600 dp use the bottom navigation bar. At 600 dp and wider, use a vertical side rail at the start edge (right in RTL) with content capped at ~720 dp (see `V-Web.dc.html`). The repo already has `shared/widgets/responsive.dart`; extend it.
8. **iPhone build without activation codes:** keep the existing build flag/behaviour. When codes are disabled, hide every redeem/coupon entry point and show only «هذا المحتوى غير متاح على حسابك» on locked content.
9. **Do not add** hearts/lives, XP, gems, leagues, friends, subscriptions or guilt-based notifications. The streak and daily goal already exist; only restyle them.
10. **Sample data in the HTML is fake.** Never hard-code it. Bind to the real providers.

## 2. Work plan: do it in phases, one commit (or PR) per phase

Work on a new branch `feature/redesign-v2`. After each phase: run `flutter analyze` and `flutter test`, fix what you broke, then write a short summary of what changed and what's next. **Pause for my review after Phase 1, Phase 2, and the first screen of Phase 3.**

**Phase 0 — Explore and confirm (no code changes).**
Read `lib/app/theme.dart`, `lib/app/router.dart`, `lib/features/shell/home_shell.dart`, `lib/shared/widgets/*` and the files in `screens/INDEX.md`. Then report back:
- the confirmed screen → file mapping (fix INDEX.md if any path differs),
- how theme / font size / dark mode are currently stored and applied,
- whether the home API returns what the new Home needs (resume item, due count, daily goal, streak, exam countdown, banners, my subjects/tracks, free content, followed teachers),
- anything in the design you believe the app cannot support today.

**Phase 1 — Design tokens and theme.**
Create the token classes (colors with soft/ink variants, radii, spacing, shadows, text styles) from `tokens.json` / `plengo_tokens.dart`. Wire them into `ThemeData` for light and dark, plus a `ThemeExtension` for the brand-specific tokens (subject colors, state colors, 3D button shadow). Hook the existing font-size setting (small/normal/large) into `textScaler` or the text theme. No screen changes yet except what the theme changes automatically.

**Phase 2 — Shared components** (put them in `lib/shared/widgets/ui_kit.dart` or a new `lib/shared/ui/` folder, whichever fits the repo). The full list with specs is in `DESIGN_SPEC.md` §4. They include:
- buttons (primary blue, brand yellow, secondary, ghost, disabled) with the 3D bottom-shadow press effect
- card, chip
- linear progress bar with a label, progress ring
- subject icon tile, list row
- pill selector, segmented control
- answer option tile with 5 states, feedback panel, bottom sheet scaffold
- bottom nav and side rail (yellow active pill)
- empty / error / loading skeleton states
- decorative confetti dots

Add a widget-catalog screen (debug-only route) that shows every component in light and dark, RTL, at all 3 font sizes.

**Phase 3 — Screens**, in this order (each one: restyle, re-arrange to match the design, keep all existing actions, handle loading/error/empty/offline/locked states):
1. Shell: bottom nav (الرئيسية · المواد · المراجعة · المحفوظات · حسابي) and the wide-screen rail
2. Home (+ daily-goal sheet, offline banner, skeleton)
3. Practice question + report sheet + exit sheet
4. Exam + question grid + review-before-finish + exit sheet
5. Results
6. Subject page (learning path), lesson page, quiz page
7. Subjects tab, notifications
8. Flashcards: deck list, deck page, browse, review/SRS
9. Review tab, mistakes bank, stats, my decks, saved
10. Account, redeem code, redeem success
11. Splash, onboarding, login (+ error), register, verify email

**Phase 4 — New screens and behaviours** (each behind a simple feature flag in one config file, default ON, so the owner can switch any of them off):
- `newDailyGoalStep`: the daily-goal step after email verification (`V-Goal`), using the existing goal settings and reminder APIs.
- `newStreakMoment`: the streak screen (`V-Streak`), shown once per day after the first finished activity.
- `learningPath`: the path layout on the subject page (`V-Subject`). With the flag off, fall back to the restyled unit accordion.
- `homeOrderV2`: the Home order (Continue + Today first, then countdown, then banners). With the flag off, use the original order: countdown → banners → Today → mistakes → continue → my subjects → free content → teachers.

**Phase 5 — Screens not in the design.** These keep their current layout but restyle with the new components:
- forgot / reset password, force update
- notification settings, my access, offline storage, connected devices
- delete-account dialog (keep its password prompt and its warning text)
- teachers list, teacher profile, track page
- card editor, legal pages

**Phase 6 — QA.** For each redesigned screen, check and fix:
- light/dark, 3 font sizes, 360 dp and 600+ dp widths
- offline behaviour, TalkBack labels, RTL with mixed LTR content
- 48 dp targets, no overflow errors

Add golden tests for the shared components and for Home, Question (unanswered / correct / wrong), Flashcard review (front/back) and Results.

## 3. When you are unsure

Ask instead of guessing when the design conflicts with existing behaviour, needs new data, or touches payments or activation codes. List all open questions together at the end of each phase.

## 4. Decisions the owner has not confirmed yet (build behind flags, mention in summaries)
- Home order change (`homeOrderV2`).
- Daily-goal onboarding step and streak screen.
- Learning-path layout vs accordion.
- Whether the exam timer keeps running when the student leaves (the exit-sheet copy depends on it; use the app's real behaviour).
- Mascot/illustrations: the design uses icons + confetti dots as placeholders. Keep illustration slots easy to swap.
