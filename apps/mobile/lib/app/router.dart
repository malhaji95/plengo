import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/account/sessions_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/shell/placeholder_tab.dart';
import '../features/splash/splash_screen.dart';
import '../features/update/force_update_screen.dart';
import 'flags.dart';
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
  static const redeem = '/redeem';

  static const public = {login, register, verifyEmail, forgotPassword, resetPassword};
}

/// Bridges Riverpod auth/update state to GoRouter's refresh mechanism.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(updateRequiredProvider, (_, _) => notifyListeners());
  }
}

/// `couponRedemption` defaults to the compile-time flag. When false the redeem route is not
/// registered at all (spec §8.7, §37.5).
GoRouter buildRouter(Ref ref, {bool couponRedemption = AppFlags.couponRedemption}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (ref.read(updateRequiredProvider)) return location == Routes.update ? null : Routes.update;

      final auth = ref.read(authControllerProvider);
      if (auth.isLoading || auth.hasError) return location == Routes.splash ? null : Routes.splash;

      final signedIn = auth.value != null;
      if (!signedIn) return Routes.public.contains(location) ? null : Routes.login;
      if (Routes.public.contains(location) || location == Routes.splash || location == Routes.update) {
        return Routes.home;
      }
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
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const PlaceholderTab(title: 'الرئيسية')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.subjects, builder: (_, _) => const PlaceholderTab(title: 'المواد')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.review, builder: (_, _) => const PlaceholderTab(title: 'المراجعة')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.saved, builder: (_, _) => const PlaceholderTab(title: 'المحفوظات')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.account,
              builder: (_, _) => const AccountScreen(),
              routes: [GoRoute(path: 'sessions', builder: (_, _) => const SessionsScreen())],
            ),
          ]),
        ],
      ),
      if (couponRedemption)
        GoRoute(
          path: Routes.redeem,
          builder: (_, _) => const PlaceholderTab(title: 'إدخال كود التفعيل'),
        ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});
