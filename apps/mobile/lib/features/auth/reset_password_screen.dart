import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/form_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _otp, _password, _confirm]) {
      c.dispose();
    }
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
      await ref
          .read(authRepositoryProvider)
          .resetPassword(email: email, otp: _otp.text.trim(), newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور، سجّل الدخول بكلمة المرور الجديدة')),
      );
      context.go(Uri(path: Routes.login, queryParameters: {'email': email}).toString());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'إعادة تعيين كلمة المرور',
      subtitle: 'أدخل الرمز الذي وصلك عبر البريد الإلكتروني ثم كلمة المرور الجديدة.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LtrTextField(controller: _email, label: 'البريد الإلكتروني', validator: Validators.email),
            const SizedBox(height: 16),
            LtrTextField(
              controller: _otp,
              label: 'رمز التحقق',
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: Validators.otp,
            ),
            const SizedBox(height: 16),
            LtrTextField(
              controller: _password,
              label: 'كلمة المرور الجديدة',
              obscureText: true,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            LtrTextField(
              controller: _confirm,
              label: 'تأكيد كلمة المرور',
              obscureText: true,
              validator: (v) => v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
            ),
            const SizedBox(height: 16),
            ErrorBanner(_error),
            const SizedBox(height: 16),
            SubmitButton(label: 'حفظ كلمة المرور', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
