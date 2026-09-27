import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/widgets/form_widgets.dart';
import 'access_format.dart';
import 'access_providers.dart';

/// Coupon code input: uppercase, Arabic/Persian digits to ASCII, only the code alphabet, dashes
/// inserted as `XXXX-XXXX-XX` (spec §9.2, §9.3). The server normalizes again; this is for typing.
class CouponCodeFormatter extends TextInputFormatter {
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const length = 10;

  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      var ch = String.fromCharCode(rune);
      if (rune >= 0x0660 && rune <= 0x0669) ch = '${rune - 0x0660}';
      if (rune >= 0x06F0 && rune <= 0x06F9) ch = '${rune - 0x06F0}';
      if (alphabet.contains(ch)) buffer.write(ch);
    }
    final raw = buffer.toString();
    return raw.length > length ? raw.substring(0, length) : raw;
  }

  static String format(String raw) {
    final parts = <String>[
      raw.substring(0, raw.length.clamp(0, 4)),
      if (raw.length > 4) raw.substring(4, raw.length.clamp(4, 8)),
      if (raw.length > 8) raw.substring(8),
    ];
    return parts.join('-');
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = format(normalize(newValue.text));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// spec §23.2 #27. Registered only in builds with COUPON_REDEMPTION=true.
class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key});

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;
  RedeemResult? _result;

  bool get _complete => CouponCodeFormatter.normalize(_code.text).length == CouponCodeFormatter.length;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_complete || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await redeemCoupon(ref, _code.text);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('إدخال كود التفعيل')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: result != null ? _Success(result: result) : _form(text),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أدخل الكود المطبوع على بطاقة التفعيل', style: text.bodyLarge),
        const SizedBox(height: 16),
        TextField(
          key: const Key('coupon-code'),
          controller: _code,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [CouponCodeFormatter()],
          style: text.headlineSmall?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
          decoration: const InputDecoration(hintText: 'XXXX-XXXX-XX', hintTextDirection: TextDirection.ltr),
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        ErrorBanner(_error),
        if (_error != null) const SizedBox(height: 16),
        SubmitButton(label: 'تفعيل', busy: _busy, onPressed: _complete ? _submit : null),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.result});

  final RedeemResult result;

  @override
  Widget build(BuildContext context) {
    final e = result.entitlement;
    final text = Theme.of(context).textTheme;
    final isTrack = e.scope.scopeType == AccessScopeScopeType.teacherTrack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('تم التفعيل بنجاح', textAlign: TextAlign.center, style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(scopeTitle(e.scope), textAlign: TextAlign.center, style: text.titleMedium),
        Text(scopeSubtitle(e.scope), textAlign: TextAlign.center, style: text.bodyMedium),
        const SizedBox(height: 8),
        Text(
          result.upgraded
              ? 'تمت ترقية وصولك إلى وصول دائم'
              : termLabel(isPermanent: e.isPermanent, expiresAt: e.expiresAt),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go(
            isTrack ? '${Routes.tracks}/${e.scope.teacherTrackId}' : '${Routes.subjects}/${e.scope.subjectId}',
          ),
          child: const Text('الذهاب إلى المحتوى'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => context.go(Routes.myAccess), child: const Text('صلاحيات الوصول')),
      ],
    );
  }
}
