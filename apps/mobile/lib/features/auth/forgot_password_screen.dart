import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/form_widgets.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
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
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) context.go(Uri(path: Routes.resetPassword, queryParameters: {'email': email}).toString());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: StateIllustration(icon: Icons.lock_reset_rounded, hue: PlengoColors.blue, size: 112),
            ),
            const SizedBox(height: 16),
            const AuthHeading(
              title: 'نسيت كلمة المرور',
              subtitle: 'أدخل بريدك الإلكتروني وسنرسل لك رمزاً لإعادة تعيين كلمة المرور.',
            ),
            const SizedBox(height: 18),
            AuthField(
              controller: _email,
              label: 'البريد الإلكتروني',
              ltr: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 12), AuthErrorBanner(_error)],
            const SizedBox(height: 16),
            PlengoButton(label: 'إرسال الرمز', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
