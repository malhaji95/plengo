import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/form_widgets.dart';
import '../onboarding/onboarding.dart';
import 'auth_widgets.dart';
import 'goal_step_marker.dart';

/// V-Login / V-LoginError.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  bool _busy = false;

  /// Server errors that belong to a field are shown under it; the rest above the button.
  FieldError? _emailError;
  FieldError? _passwordError;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _emailError = null;
      _passwordError = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final email = _email.text.trim().toLowerCase();
    final db = ref.read(databaseProvider);
    final router = ref.read(routerProvider);
    try {
      final goalStep = await GoalStepMarker.isPending(db);
      await ref.read(authControllerProvider.notifier).login(email, _password.text);
      // First sign-in after verifying on this device: the daily-goal step instead of Home.
      if (goalStep) {
        await GoalStepMarker.clear(db);
        router.go(Routes.onboardingGoal);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'AUTH_EMAIL_NOT_VERIFIED') {
        await ref.read(authRepositoryProvider).resendVerification(email).catchError((_) {});
        if (mounted) context.go(Uri(path: Routes.verifyEmail, queryParameters: {'email': email}).toString());
        return;
      }
      setState(() {
        switch (e.code) {
          case 'AUTH_INVALID_CREDENTIALS':
            _passwordError = (message: e.message, recovery: 'تحقّق منها، أو استخدم «نسيت كلمة المرور؟».');
          case 'VALIDATION_ERROR':
            _emailError = (message: e.message, recovery: null);
          default:
            _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearServerErrors() {
    if (_emailError == null && _passwordError == null && _error == null) return;
    setState(() {
      _emailError = null;
      _passwordError = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seen = ref.watch(onboardingSeenProvider);
    if (seen.value == false) return const OnboardingView();
    // A brief blank frame while the flag loads, so a first visit never flashes the form.
    if (!seen.hasValue && !seen.hasError) return const Scaffold();
    final s = context.surface;
    return AuthBandScaffold(
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(title: 'أهلاً بعودتك!', subtitle: 'أدخل بريدك الإلكتروني وكلمة المرور.'),
              const SizedBox(height: 18),
              AuthField(
                fieldKey: const Key('login.email'),
                controller: _email,
                label: 'البريد الإلكتروني',
                ltr: true,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                error: _emailError,
                onChanged: (_) => _clearServerErrors(),
              ),
              const SizedBox(height: 16),
              AuthField(
                fieldKey: const Key('login.password'),
                controller: _password,
                label: 'كلمة المرور',
                ltr: true,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').isEmpty ? 'أدخل كلمة المرور' : null,
                error: _passwordError,
                onChanged: (_) => _clearServerErrors(),
              ),
              AuthLink(
                label: 'نسيت كلمة المرور؟',
                alignment: AlignmentDirectional.centerStart,
                onPressed: () => context.push(Routes.forgotPassword),
              ),
              if (_error != null) ...[const SizedBox(height: 8), AuthErrorBanner(_error)],
              const SizedBox(height: 12),
              PlengoButton(key: const Key('login.submit'), label: 'دخول', busy: _busy, onPressed: _submit),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('ليس لديك حساب؟', style: PlengoType.sub.copyWith(color: s.mute)),
                  AuthLink(label: 'أنشئ حساباً جديداً', onPressed: () => context.push(Routes.register)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
