import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/form_widgets.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendCooldown = 60;
  final _form = GlobalKey<FormState>();
  final _otp = TextEditingController();
  bool _busy = false;
  String? _error;
  int _cooldown = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) t.cancel();
      if (mounted) setState(() => _cooldown--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmail(email: widget.email, otp: _otp.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تفعيل بريدك الإلكتروني، سجّل الدخول الآن')));
      context.go(Uri(path: Routes.login, queryParameters: {'email': widget.email}).toString());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رمز جديد')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'تفعيل البريد الإلكتروني',
      subtitle: 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى:',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.email, textDirection: TextDirection.ltr, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            LtrTextField(
              fieldKey: const Key('verify.otp'),
              controller: _otp,
              label: 'رمز التحقق',
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              validator: Validators.otp,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ErrorBanner(_error),
            const SizedBox(height: 16),
            SubmitButton(key: const Key('verify.submit'), label: 'تحقق', busy: _busy, onPressed: _submit),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _cooldown > 0 ? null : _resend,
              child: Text(_cooldown > 0 ? 'إعادة إرسال الرمز بعد $_cooldown ث' : 'إعادة إرسال الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}
