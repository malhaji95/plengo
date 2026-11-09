/// Arabic validators shared by the auth forms (spec §25).
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'أدخل البريد الإلكتروني';
    if (!_email.hasMatch(value)) return 'البريد الإلكتروني غير صحيح';
    return null;
  }

  static String? password(String? v) {
    if ((v ?? '').isEmpty) return 'أدخل كلمة المرور';
    if (v!.length < 8) return 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';
    if (v.length > 128) return 'كلمة المرور طويلة جداً';
    return null;
  }

  static String? required(String? v, String message) => (v?.trim() ?? '').isEmpty ? message : null;

  static String? fullName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'أدخل الاسم الكامل';
    if (value.length < 2) return 'الاسم قصير جداً';
    return null;
  }

  static String? otp(String? v) =>
      RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : 'أدخل الرمز المكوّن من 6 أرقام';
}
