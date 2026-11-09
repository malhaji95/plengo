import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/form_widgets.dart';
import 'auth_widgets.dart';
import 'goal_step_marker.dart';

/// V-Verify: the 6-digit email code.
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
  FieldError? _otpError;
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
    setState(() {
      _error = null;
      _otpError = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmail(email: widget.email, otp: _otp.text.trim());
      // The next sign-in on this device opens the daily-goal step (flag newDailyGoalStep).
      await GoalStepMarker.mark(ref.read(databaseProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تفعيل بريدك الإلكتروني، سجّل الدخول الآن')));
      context.go(Uri(path: Routes.login, queryParameters: {'email': widget.email}).toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'AUTH_OTP_INVALID') {
          _otpError = (message: e.message, recovery: 'تحقّق من الرمز في بريدك، أو اطلب رمزاً جديداً.');
        } else {
          _error = e.message;
        }
      });
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

  void _editEmail() => context.go(Uri(path: Routes.register, queryParameters: {'email': widget.email}).toString());

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AuthPageScaffold(
      onBack: _editEmail,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConfettiDots(
                spread: 14,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(color: s.actionSoft, shape: BoxShape.circle),
                  child: ExcludeSemantics(child: Icon(Icons.mark_email_unread_rounded, size: 56, color: s.action)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AuthHeading(
              center: true,
              title: 'تفعيل البريد الإلكتروني',
              subtitle: 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى:',
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: PlengoType.rowTitle.copyWith(color: s.ink),
            ),
            AuthLink(label: 'تعديل البريد', alignment: Alignment.center, onPressed: _editEmail),
            const SizedBox(height: 12),
            OtpBoxes(
              fieldKey: const Key('verify.otp'),
              controller: _otp,
              error: _otpError,
              validator: Validators.otp,
              onChanged: (_) {
                if (_otpError != null) setState(() => _otpError = null);
              },
              onCompleted: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: _cooldown > 0
                  ? Text(
                      'إعادة إرسال الرمز بعد $_cooldown ث',
                      textAlign: TextAlign.center,
                      style: PlengoType.caption.copyWith(color: s.mute, fontWeight: FontWeight.w600),
                    )
                  : AuthLink(label: 'إعادة إرسال الرمز', onPressed: _resend),
            ),
            if (_error != null) ...[const SizedBox(height: 12), AuthErrorBanner(_error)],
            const SizedBox(height: 16),
            PlengoButton(key: const Key('verify.submit'), label: 'تحقق', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Six LTR digit boxes over one invisible text field, so the platform's one-time-code autofill and
/// paste keep working; [onCompleted] runs on the keyboard's done action. Arabic-Indic digits are converted to 0–9. The active box has a blue border.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.controller,
    this.fieldKey,
    this.validator,
    this.error,
    this.onChanged,
    this.onCompleted,
    this.length = 6,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;
  final FieldError? error;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCompleted;
  final int length;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator == null ? null : (_) => widget.validator!(widget.controller.text),
      builder: (field) {
        final error = field.errorText != null ? (message: field.errorText!, recovery: null) : widget.error;
        final code = widget.controller.text;
        final active = _focus.hasFocus ? code.length.clamp(0, widget.length - 1) : -1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 46),
                              child: _Box(
                                digit: i < code.length ? code[i] : '',
                                active: i == active,
                                error: error != null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.011,
                      child: TextField(
                        key: widget.fieldKey,
                        controller: widget.controller,
                        focusNode: _focus,
                        maxLength: widget.length,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        textDirection: TextDirection.ltr,
                        showCursor: false,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [_DigitsFormatter(widget.length)],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          labelText: 'رمز التحقق',
                        ),
                        onChanged: (v) {
                          field.didChange(v);
                          widget.onChanged?.call(v);
                        },
                        onSubmitted: (_) => widget.onCompleted?.call(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) FieldErrorText(message: error.message, recovery: error.recovery),
          ],
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active, required this.error});

  final String digit;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final border = error ? PlengoColors.redStrong : (active ? s.action : s.line);
    return AspectRatio(
      aspectRatio: 46 / 58,
      child: Container(
        decoration: BoxDecoration(
          color: error ? PlengoColors.red.soft : s.card,
          borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
          border: Border.all(color: border, width: 2),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Text(digit, style: PlengoType.section.copyWith(fontSize: 22, color: error ? PlengoColors.ink : s.ink)),
        ),
      ),
    );
  }
}

/// Keeps only digits (Arabic-Indic and Persian digits become 0–9), at most [length].
class _DigitsFormatter extends TextInputFormatter {
  _DigitsFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      if (rune >= 0x30 && rune <= 0x39) buffer.writeCharCode(rune);
      if (rune >= 0x0660 && rune <= 0x0669) buffer.write(rune - 0x0660);
      if (rune >= 0x06F0 && rune <= 0x06F9) buffer.write(rune - 0x06F0);
    }
    var text = buffer.toString();
    if (text.length > length) text = text.substring(0, length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
