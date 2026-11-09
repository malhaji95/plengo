# Design screen → Dart file

All paths are under `apps/mobile/lib/features/`.

| Design | Replaces |
|---|---|
| V-Splash | `splash/splash_screen.dart` |
| V-Onboarding | `onboarding/onboarding.dart` |
| V-Login, V-LoginError | `auth/login_screen.dart` |
| V-Register | `auth/register_screen.dart` (+ `auth/placement_picker.dart`) |
| V-Verify | `auth/verify_email_screen.dart` |
| V-Goal (new) | new `onboarding/goal_step_screen.dart`, shown after email verification |
| V-Home, V-HomeDark, V-HomeLarge, V-Offline, V-Loading | `home/home_tab.dart` |
| V-Notifications | `home/notification_screens.dart` |
| V-Subjects | `subjects/subjects_screen.dart` |
| V-Subject | `subjects/subject_screen.dart` |
| V-Lesson | `subjects/lesson_screen.dart` |
| V-Quiz | `quizzes/quizzes_screen.dart` (`QuizScreen`) |
| V-Question | `questions/question_view.dart` (practice) and `quizzes/practice_attempt_screen.dart` |
| V-Exam | `quizzes/exam_screen.dart` |
| V-Results | `quizzes/results_screen.dart` |
| V-Streak (new) | new `home/streak_screen.dart` |
| V-FcDecks | `flashcards/decks_screen.dart` |
| V-FcDeck | `flashcards/deck_screen.dart` |
| V-FcBrowse | `flashcards/browse_screen.dart` |
| V-Flashcards | `flashcards/study_screen.dart` |
| V-Review | `flashcards/review_tab.dart` (+ `quizzes/random_practice_screen.dart`) |
| V-Mistakes | `learning/mistakes_screen.dart` |
| V-Stats | `learning/stats_screen.dart` |
| V-MyDecks | `my_decks/my_decks_screen.dart`, `my_decks/my_deck_screen.dart`, `my_decks/card_editor_screen.dart` |
| V-Saved | `bookmarks/saved_tab.dart` |
| V-Account | `account/account_screen.dart` |
| V-Redeem, V-RedeemSuccess | `access/redeem_screen.dart` |
| V-ErrorRetry | `shared/widgets/async_view.dart` (error state) |
| V-Web | `shell/home_shell.dart` + `shared/widgets/responsive.dart` |
| V-Styles | reference sheet for the shared components (`shared/ui/`) |

The screen HTML files here are the canvas at https://claude.ai/artifact/NxYuo9qvVHPdzmfXwQQpa9
(version 19, after the colour fix: an earlier find-and-replace had turned `FF` in hex colours into
the font name).
