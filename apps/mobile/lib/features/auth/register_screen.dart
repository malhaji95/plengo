import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/form_widgets.dart';
import '../subjects/placement_picker.dart';

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
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
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
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'إنشاء حساب',
      subtitle: 'سنرسل رمز تحقق إلى بريدك الإلكتروني لتفعيل الحساب.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('register.name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.fullName,
            ),
            const SizedBox(height: 16),
            LtrTextField(
              fieldKey: const Key('register.email'),
              controller: _email,
              label: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            LtrTextField(
              fieldKey: const Key('register.password'),
              controller: _password,
              label: 'كلمة المرور',
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            LtrTextField(
              fieldKey: const Key('register.confirm'),
              controller: _confirm,
              label: 'تأكيد كلمة المرور',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
            ),
            const SizedBox(height: 16),
            PlacementPicker(value: _placement, onChanged: (v) => setState(() => _placement = v)),
            const SizedBox(height: 16),
            ErrorBanner(_error),
            const SizedBox(height: 16),
            SubmitButton(key: const Key('register.submit'), label: 'إنشاء الحساب', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
