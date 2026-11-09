import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/brand_logo.dart';
import '../auth/auth_widgets.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'access_format.dart';
import 'access_providers.dart';
import '../offline/download_widgets.dart';

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

/// Where the student came from, read without changing the route: `?subjectId=` / `?teacherTrackId=`
/// on the URL, or the same keys in a `Map` passed as `extra`. Both null when opened from the account.
typedef RedeemOrigin = ({String? subjectId, String? teacherTrackId});

RedeemOrigin redeemOriginOf(BuildContext context) {
  try {
    final state = GoRouterState.of(context);
    final extra = state.extra;
    String? read(String key) {
      final fromQuery = state.uri.queryParameters[key];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
      final fromExtra = extra is Map ? extra[key] : null;
      return fromExtra is String && fromExtra.isNotEmpty ? fromExtra : null;
    }

    return (subjectId: read('subjectId'), teacherTrackId: read('teacherTrackId'));
  } on Object {
    return (subjectId: null, teacherTrackId: null);
  }
}

/// V-Redeem / V-RedeemSuccess (spec §23.2 #27). Registered only in builds with COUPON_REDEMPTION=true.
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
      // Offer the activated content for offline use (§22.2).
      final scope = result.entitlement.scope;
      if (mounted) {
        await offerDownloadAfterRedemption(context, ref, (
          subjectId: scope.subjectId,
          teacherTrackId: scope.scopeType == AccessScopeScopeType.teacherTrack ? scope.teacherTrackId : null,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// DECISIONS #15: back to the subject (or track) the student came from, whose free items are open;
  /// otherwise the Subjects tab.
  void _tryFree(RedeemOrigin origin) {
    if (origin.subjectId != null) {
      context.go('${Routes.subjects}/${origin.subjectId}');
    } else if (origin.teacherTrackId != null) {
      context.go('${Routes.tracks}/${origin.teacherTrackId}');
    } else {
      context.go(Routes.subjects);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        leading: const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        title: result == null ? const Text('إدخال كود التفعيل') : null,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: result != null ? RedeemSuccessView(result: result) : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    final s = context.surface;
    final origin = redeemOriginOf(context);
    final fromLocked = origin.subjectId != null || origin.teacherTrackId != null;
    final enabled = _complete && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fromLocked) ...[_LockedNotice(origin: origin), const SizedBox(height: 18)],
        const _ActivationCard(),
        const SizedBox(height: 18),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أدخل الكود المطبوع على بطاقة التفعيل',
                style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink),
              ),
              const SizedBox(height: 6),
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
                style: PlengoType.section.copyWith(
                  fontSize: 22,
                  letterSpacing: 3,
                  color: _error != null ? PlengoColors.ink : s.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XX',
                  hintTextDirection: TextDirection.ltr,
                  hintStyle: PlengoType.section.copyWith(fontSize: 22, letterSpacing: 3, color: s.mute),
                  filled: true,
                  fillColor: _error != null ? PlengoColors.red.soft : s.card,
                  constraints: const BoxConstraints(minHeight: 64),
                  contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 18),
                  enabledBorder: _border(_error != null ? PlengoColors.redStrong : s.line),
                  focusedBorder: _border(_error != null ? PlengoColors.redStrong : s.action),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) FieldErrorText(message: _error!),
        const SizedBox(height: 18),
        // A FilledButton in the primary style (with the 3D shadow when enabled).
        AnimatedContainer(
          duration: PlengoMotion.of(context, PlengoMotion.press),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlengoRadius.button),
            boxShadow: enabled ? [BoxShadow(color: s.actionShadow, offset: const Offset(0, 4))] : const [],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: s.action,
              foregroundColor: s.onAction,
              minimumSize: const Size.fromHeight(PlengoSpace.button),
              textStyle: PlengoType.button,
            ),
            onPressed: _complete && !_busy ? _submit : null,
            child: _busy
                ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: s.mute))
                : const Text('تفعيل'),
          ),
        ),
        const SizedBox(height: 8),
        PlengoButton(
          label: 'جرّب الدروس المجانية أولاً',
          variant: PlengoButtonVariant.ghost,
          onPressed: () => _tryFree(origin),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(PlengoRadius.input),
    borderSide: BorderSide(color: c, width: 2),
  );
}

/// «هذا المحتوى يحتاج إلى تفعيل» with the subject or track name when it is already loaded.
class _LockedNotice extends ConsumerWidget {
  const _LockedNotice({required this.origin});

  final RedeemOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = origin.subjectId != null
        ? ref.watch(subjectOutlineProvider(origin.subjectId!)).value?.subject.nameAr
        : ref.watch(trackProvider(origin.teacherTrackId!)).value?.track.titleAr;
    return PlengoCard(
      color: PlengoColors.red.soft,
      child: Row(
        children: [
          const SubjectIconTile(icon: Icons.lock_rounded, hue: PlengoColors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هذا المحتوى يحتاج إلى تفعيل', style: PlengoType.rowTitle.copyWith(color: PlengoColors.ink)),
                if (name != null) Text(name, style: PlengoType.caption.copyWith(color: PlengoColors.red.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration of the yellow activation card with the code pattern. Decorative.
class _ActivationCard extends StatelessWidget {
  const _ActivationCard();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: ConfettiDots(
          spread: 18,
          child: Container(
            width: 220,
            height: 136,
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
              color: PlengoColors.yellow.base,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: PlengoColors.yellow.shadow, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrandLogo(height: 24, onBrand: true),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    'XXXX-XXXX-XX',
                    textDirection: TextDirection.ltr,
                    style: PlengoType.rowTitle.copyWith(letterSpacing: 2, color: PlengoColors.yellow.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// V-RedeemSuccess: green check with confetti, the activated scope and its access date, then
/// «الذهاب إلى المحتوى». The offline download offer opens as a sheet on mobile.
class RedeemSuccessView extends StatelessWidget {
  const RedeemSuccessView({super.key, required this.result});

  final RedeemResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final e = result.entitlement;
    final isTrack = e.scope.scopeType == AccessScopeScopeType.teacherTrack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: ConfettiDots(
            spread: 22,
            child: Container(
              width: 130,
              height: 130,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PlengoColors.green.base,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: PlengoColors.green.soft, spreadRadius: 12)],
              ),
              child: const ExcludeSemantics(child: Icon(Icons.check_rounded, size: 72, color: PlengoColors.ink)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            'تم التفعيل بنجاح',
            textAlign: TextAlign.center,
            style: PlengoType.title.copyWith(color: s.ink),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          scopeTitle(e.scope),
          textAlign: TextAlign.center,
          style: PlengoType.section.copyWith(color: s.ink),
        ),
        Text(
          scopeSubtitle(e.scope),
          textAlign: TextAlign.center,
          style: PlengoType.sub.copyWith(color: s.mute),
        ),
        const SizedBox(height: 12),
        Center(
          child: PlengoChip(
            label: result.upgraded
                ? 'تمت ترقية وصولك إلى وصول دائم'
                : termLabel(isPermanent: e.isPermanent, expiresAt: e.expiresAt),
            hue: PlengoColors.green,
            icon: Icons.event_available_rounded,
          ),
        ),
        const SizedBox(height: 28),
        PlengoButton(
          label: 'الذهاب إلى المحتوى',
          variant: PlengoButtonVariant.brand,
          onPressed: () => context.go(
            isTrack ? '${Routes.tracks}/${e.scope.teacherTrackId}' : '${Routes.subjects}/${e.scope.subjectId}',
          ),
        ),
        const SizedBox(height: 8),
        PlengoButton(
          label: 'صلاحيات الوصول',
          variant: PlengoButtonVariant.ghost,
          onPressed: () => context.go(Routes.myAccess),
        ),
      ],
    );
  }
}
