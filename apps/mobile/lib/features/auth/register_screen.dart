import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/form_widgets.dart';
import '../legal/legal_screen.dart';
import '../subjects/placement_picker.dart' show PlacementDraft, emptyPlacement;
import 'auth_widgets.dart';
import 'stage_picker.dart';

/// V-Register. `?email=` (from «تعديل البريد» on the verify screen) pre-fills the email.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  PlacementDraft _placement = emptyPlacement;
  bool _busy = false;
  bool _prefilled = false;
  FieldError? _emailError;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    try {
      final email = GoRouterState.of(context).uri.queryParameters['email'];
      if (email != null && email.isNotEmpty) _email.text = email;
    } on Object {
      // Not under the router (e.g. a widget test of the screen alone): nothing to pre-fill.
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _emailError = null;
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final email = _email.text.trim().toLowerCase();
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _name.text.trim(),
            email: email,
            password: _password.text,
            educationLevelId: _placement.levelId!,
            universityId: _placement.universityId,
            facultyId: _placement.facultyId,
            academicYearId: _placement.academicYearId,
          );
      if (mounted) context.go(Uri(path: Routes.verifyEmail, queryParameters: {'email': email}).toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'AUTH_EMAIL_TAKEN') {
          _emailError = (message: e.message, recovery: 'استخدم بريداً آخر، أو سجّل الدخول بهذا البريد.');
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AuthPageScaffold(
      title: 'إنشاء حساب',
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('سنرسل رمز تحقق إلى بريدك الإلكتروني لتفعيل الحساب.', style: PlengoType.sub.copyWith(color: s.mute)),
              const SizedBox(height: 14),
              AuthField(
                fieldKey: const Key('register.name'),
                controller: _name,
                label: 'الاسم الكامل',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
              ),
              const SizedBox(height: 14),
              AuthField(
                fieldKey: const Key('register.email'),
                controller: _email,
                label: 'البريد الإلكتروني',
                ltr: true,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                error: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 14),
              AuthField(
                fieldKey: const Key('register.password'),
                controller: _password,
                label: 'كلمة المرور',
                ltr: true,
                obscureText: true,
                hint: '8 أحرف على الأقل',
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              AuthField(
                fieldKey: const Key('register.confirm'),
                controller: _confirm,
                label: 'تأكيد كلمة المرور',
                ltr: true,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) => v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
              ),
              const SizedBox(height: 16),
              StagePicker(value: _placement, onChanged: (v) => setState(() => _placement = v)),
              const SizedBox(height: 16),
              LegalConsentText(
                onOpen: (doc) => context.push(doc == LegalDocument.privacy ? Routes.privacy : Routes.terms),
              ),
              if (_error != null) ...[const SizedBox(height: 12), AuthErrorBanner(_error)],
              const SizedBox(height: 16),
              PlengoButton(key: const Key('register.submit'), label: 'إنشاء الحساب', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
