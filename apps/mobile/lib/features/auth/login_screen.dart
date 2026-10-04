import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/form_widgets.dart';
import '../onboarding/onboarding.dart';

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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim().toLowerCase();
    try {
      await ref.read(authControllerProvider.notifier).login(email, _password.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'AUTH_EMAIL_NOT_VERIFIED') {
        await ref.read(authRepositoryProvider).resendVerification(email).catchError((_) {});
        if (mounted) context.go(Uri(path: Routes.verifyEmail, queryParameters: {'email': email}).toString());
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seen = ref.watch(onboardingSeenProvider);
    if (seen.value == false) return const OnboardingView();
    // A brief blank frame while the flag loads, so a first visit never flashes the form.
    if (!seen.hasValue && !seen.hasError) return const Scaffold();
    return AuthScaffold(
      title: 'تسجيل الدخول',
      subtitle: 'أهلاً بعودتك! أدخل بريدك الإلكتروني وكلمة المرور.',
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LtrTextField(
                fieldKey: const Key('login.email'),
                controller: _email,
                label: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              LtrTextField(
                fieldKey: const Key('login.password'),
                controller: _password,
                label: 'كلمة المرور',
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').isEmpty ? 'أدخل كلمة المرور' : null,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => context.push(Routes.forgotPassword),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              ErrorBanner(_error),
              const SizedBox(height: 16),
              SubmitButton(key: const Key('login.submit'), label: 'دخول', busy: _busy, onPressed: _submit),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(Routes.register),
                child: const Text('ليس لديك حساب؟ أنشئ حساباً جديداً'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
