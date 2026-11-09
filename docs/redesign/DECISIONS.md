# Redesign v2 — decisions on the open questions

The owner asked to build what the design needs and the app lacks, then apply the design, on the
existing branch (`claude/friendly-gates-mcmxsy`). These are the calls made for the gaps found in
Phase 0. They override DESIGN_SPEC.md where they differ.

## New data (built in the API, contracts and generated clients)

1. **Locked subjects (V-Subjects).** The student subject list gains `hasAccess: boolean`: true when
   the student has an active entitlement or a running promotion for the subject's general content.
   Locked rows show the red «مقفل» chip with a lock icon.
2. **Streak week row (V-Streak).** Home `today` gains `week: boolean[7]`, the last seven business
   days (oldest first, today last) where the daily goal was met. The streak means "days with the
   goal met"; the copy says so («أيام متتالية حققت فيها هدفك»).
3. **Review-reminder switch (V-Goal, notification settings).** Notification preferences gain
   `reviewReminder: boolean` (default true). The due-card reminder job sends only when it is true
   (and `learning` is true). Turning `learning` off still silences everything.
4. **Free content cards (Home).** `freeSubjects` items gain `coverUrl` (the subject cover, nullable).
   Without a cover the card uses the subject colour.

## Derived in the app (no API change)

5. **Continue hero progress (Home).** From the existing progress endpoint for the resume item's
   scope: the lesson's `completionPercent`, else the unit's, else the subject's.
6. **My subjects & tracks rings (Home).** From the existing progress endpoint, one cached call per
   scope (`subjectProgressProvider`).
7. **Learning path node states (V-Subject).** From the per-lesson `completionPercent`: 100 = done;
   the current node is the resume item's lesson in this subject, else the first lesson below 100;
   the rest are upcoming. Every unlocked lesson stays tappable. The unit-quiz node is the first
   quiz placed on the unit (none: no node). There is no "locked unit" in the data model (access is
   per subject or track), so locked units are not drawn; the subject-level locked notice stays.
8. **Per-deck due chips (V-FcDecks).** One `due(subjectId)` call grouped by `card.deckId`.
9. **Deck page counts and time (V-FcDeck).** New / learning / review from the local SRS queue for
   the deck; time = due cards × 8 seconds, rounded up to whole minutes («حوالي N دقائق»).
10. **Correct-in-a-row chip (V-Question).** Counted inside the practice session; shown at ≥ 3.
11. **Subject colours.** No colour in the data: a stable hash of the subject id picks one of the six
    hues (yellow, blue, green, red, orange, pink).

## Copy and behaviour

12. **Exam exit sheet.** The timer runs on the server, so the copy is «إجاباتك محفوظة، لكن الوقت
    مستمر. يمكنك العودة من صفحة الاختبار بزر «متابعة الاختبار».»
13. **Practice exit sheet.** In a quiz practice attempt: «تقدّمك محفوظ». In question-bank practice
    (not resumable): «إجاباتك محفوظة في إحصائياتك وبنك الأخطاء».
14. **Official flashcard images** are shown as they are (they already carry their frame and logo).
    No extra deck-colour frame or logo around them.
15. **«جرّب الدروس المجانية أولاً» (V-Redeem)** opens the subject the student came from (its free
    items are open), else the Subjects tab.
16. **Font sizes** follow the design: 0.88 / 1.0 / 1.16.
17. **Feature flags** (one file, `lib/app/redesign_flags.dart`, all default on): `newDailyGoalStep`,
    `newStreakMoment`, `learningPath`, `homeOrderV2`.
