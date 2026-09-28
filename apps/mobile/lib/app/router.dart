import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/access/access_providers.dart';
import '../features/access/my_access_screen.dart';
import '../features/access/redeem_screen.dart';
import '../features/account/account_screen.dart';
import '../features/account/placement_screen.dart';
import '../features/account/sessions_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/flashcards/browse_screen.dart';
import '../features/flashcards/deck_screen.dart';
import '../features/flashcards/decks_screen.dart';
import '../features/flashcards/review_tab.dart';
import '../features/flashcards/study_screen.dart';
import '../features/bookmarks/saved_tab.dart';
import '../features/learning/home_tab.dart';
import '../features/learning/mistakes_screen.dart';
import '../features/learning/stats_screen.dart';
import '../features/quizzes/attempt_route.dart';
import '../features/quizzes/quizzes_screen.dart';
import '../features/quizzes/random_practice_screen.dart';
import '../features/quizzes/results_screen.dart';
import '../features/questions/questions_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/subjects/subject_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/teachers/teacher_screen.dart';
import '../features/teachers/teachers_screen.dart';
import '../features/teachers/track_screen.dart';
import '../features/update/force_update_screen.dart';
import 'providers.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const update = '/update';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const subjects = '/subjects';
  static const review = '/review';
  static const saved = '/saved';
  static const account = '/account';
  static const sessions = '/account/sessions';
  static const placement = '/account/placement';
  static const following = '/account/following';
  static const myAccess = '/account/access';
  static const teachers = '/teachers';
  static const tracks = '/tracks';
  static const redeem = '/redeem';
  static const decks = '/decks';
  static const dueStudy = '/review/study';
  static const mistakes = '/review/mistakes';
  static const stats = '/review/stats';
  static const quizzes = '/quizzes';
  static const attempts = '/attempts';
  static const randomPractice = '/practice/random';

  static const public = {login, register, verifyEmail, forgotPassword, resetPassword};
}

/// Bridges Riverpod auth/update state to GoRouter's refresh mechanism.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    // Only a change of signed-in status matters for redirects; profile edits must not reset the stack.
    ref.listen(
      authControllerProvider.select((s) => (s.isLoading, s.hasError, s.value != null)),
      (_, _) => notifyListeners(),
    );
    ref.listen(updateRequiredProvider, (_, _) => notifyListeners());
  }
}

/// `couponRedemption` is the compile-time flag (see [couponRedemptionProvider]). When false the redeem route is not
/// registered at all (spec §8.7, §37.5).
GoRouter buildRouter(Ref ref, {required bool couponRedemption}) {
  // Web: pushed screens (e.g. register) show their own URL too (spec §24 deep links).
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (ref.read(updateRequiredProvider)) return location == Routes.update ? null : Routes.update;

      final auth = ref.read(authControllerProvider);
      if (auth.isLoading || auth.hasError) {
        // Remember a deep link (e.g. /subjects/<id> after a web reload) while the session restores.
        if (location == Routes.splash) return null;
        return Uri(path: Routes.splash, queryParameters: {'from': state.uri.toString()}).toString();
      }

      final signedIn = auth.value != null;
      if (!signedIn) return Routes.public.contains(location) ? null : Routes.login;
      if (location == Routes.splash) {
        final from = state.uri.queryParameters['from'];
        final safe = from != null && from.startsWith('/') && !from.startsWith('//');
        return safe && !Routes.public.contains(Uri.parse(from).path) && Uri.parse(from).path != Routes.splash
            ? from
            : Routes.home;
      }
      if (Routes.public.contains(location) || location == Routes.update) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.update, builder: (_, _) => const ForceUpdateScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, state) => LoginScreen(initialEmail: state.uri.queryParameters['email']),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (_, state) => VerifyEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) => ResetPasswordScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeTab())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.subjects,
                builder: (_, _) => const SubjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => SubjectScreen(subjectId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'decks',
                        builder: (_, state) => SubjectDecksRoute(subjectId: state.pathParameters['id']!),
                      ),
                      GoRoute(
                        path: 'quizzes',
                        builder: (_, state) => SubjectQuizzesRoute(
                          subjectId: state.pathParameters['id']!,
                          lessonId: state.uri.queryParameters['lessonId'],
                        ),
                      ),
                      GoRoute(
                        path: 'questions',
                        builder: (_, state) => SubjectQuestionsRoute(
                          subjectId: state.pathParameters['id']!,
                          unitId: state.uri.queryParameters['unitId'],
                          lessonId: state.uri.queryParameters['lessonId'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: Routes.teachers,
                builder: (_, _) => const TeachersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => TeacherScreen(teacherId: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: '${Routes.tracks}/:id',
                builder: (_, state) => TrackScreen(trackId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'questions',
                    builder: (_, state) => TrackQuestionsRoute(trackId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'decks',
                    builder: (_, state) => TrackDecksRoute(trackId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'quizzes',
                    builder: (_, state) => TrackQuizzesRoute(trackId: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: '${Routes.quizzes}/:id',
                builder: (_, state) => QuizScreen(quizId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: '${Routes.decks}/:id',
                builder: (_, state) => DeckScreen(deckId: state.pathParameters['id']!),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.review,
                builder: (_, _) => const ReviewTab(),
                routes: [
                  GoRoute(path: 'mistakes', builder: (_, _) => const MistakesScreen()),
                  GoRoute(
                    path: 'stats',
                    builder: (_, _) => const StatsScreen(),
                    routes: [
                      GoRoute(
                        path: 'subjects/:id',
                        builder: (_, state) => SubjectStatsScreen(subjectId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.saved, builder: (_, _) => const SavedTab())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountScreen(),
                routes: [
                  GoRoute(path: 'sessions', builder: (_, _) => const SessionsScreen()),
                  GoRoute(path: 'placement', builder: (_, _) => const PlacementScreen()),
                  GoRoute(path: 'following', builder: (_, _) => const FollowedTeachersScreen()),
                  GoRoute(path: 'access', builder: (_, _) => const MyAccessScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen study modes (outside the tab shell).
      GoRoute(
        path: '${Routes.decks}/:id/browse',
        builder: (_, state) => BrowseScreen(deckId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.decks}/:id/study',
        builder: (_, state) =>
            StudyScreen(source: (deckId: state.pathParameters['id']!, subjectId: null), title: 'مراجعة'),
      ),
      GoRoute(
        path: Routes.dueStudy,
        builder: (_, state) => StudyScreen(
          source: (deckId: null, subjectId: state.uri.queryParameters['subjectId']),
          title: 'كل البطاقات المستحقة',
        ),
      ),
      // Attempts are full-screen: practice, exam or results (spec §15).
      GoRoute(
        path: '${Routes.attempts}/:id',
        builder: (_, state) => AttemptRoute(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.attempts}/:id/results',
        builder: (_, state) => ResultsScreen(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.randomPractice,
        builder: (_, state) => RandomPracticeScreen(
          subjectId: state.uri.queryParameters['subjectId'] ?? '',
          teacherTrackId: state.uri.queryParameters['teacherTrackId'],
        ),
      ),
      if (couponRedemption) GoRoute(path: Routes.redeem, builder: (_, _) => const RedeemScreen()),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref, couponRedemption: ref.read(couponRedemptionProvider));
  ref.onDispose(router.dispose);
  return router;
});
