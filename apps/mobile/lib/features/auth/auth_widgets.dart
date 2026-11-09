import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/brand_logo.dart';

/// Shared pieces of the redesigned entry screens (V-Login, V-Register, V-Verify, forgot/reset password).

/// Red error text that stays readable on the neutral background in both themes.
Color fieldErrorColor(PlengoSurface s) => s.isDark ? PlengoColors.red.base : PlengoColors.red.ink;

/// A field error with an optional recovery line, shown under the field (V-LoginError).
typedef FieldError = ({String message, String? recovery});

/// The alert line under a field: icon + message (+ recovery text). Announced when it appears.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText({super.key, required this.message, this.recovery});

  final String message;
  final String? recovery;

  @override
  Widget build(BuildContext context) {
    final color = fieldErrorColor(context.surface);
    final style = PlengoType.chip.copyWith(fontSize: 13, height: 1.6, color: color);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(Icons.error_rounded, size: 18, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: style),
                  if (recovery != null) Text(recovery!, style: style.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled input (spec: label 14/700 above a 54-high field, 2 px border, radius 16). Validation and
/// server errors show under the field with a red border, red-soft background and an alert icon, never
/// colour alone. [ltr] keeps emails, codes and passwords left-to-right. Password fields get a show/hide
/// button.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.validator,
    this.error,
    this.hint,
    this.ltr = false,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.maxLength,
    this.enabled = true,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;

  /// Key of the inner [TextField] (tests and autofill use it).
  final Key? fieldKey;
  final FormFieldValidator<String>? validator;

  /// A server error attached to this field; a validation error wins over it.
  final FieldError? error;

  /// Helper line under the field when there is no error (e.g. «8 أحرف على الأقل»).
  final String? hint;
  final bool ltr;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return FormField<String>(
      validator: widget.validator == null ? null : (_) => widget.validator!(widget.controller.text),
      builder: (state) {
        final validation = state.errorText;
        final FieldError? error = validation != null ? (message: validation, recovery: null) : widget.error;
        final bad = error != null;
        OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(PlengoRadius.input),
          borderSide: BorderSide(color: c, width: 2),
        );
        final ink = bad ? PlengoColors.ink : s.ink;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label, style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink)),
                  const SizedBox(height: 6),
                  TextField(
                    key: widget.fieldKey,
                    controller: widget.controller,
                    enabled: widget.enabled,
                    textDirection: widget.ltr ? TextDirection.ltr : null,
                    textAlign: widget.ltr ? TextAlign.left : TextAlign.start,
                    obscureText: _hidden,
                    autocorrect: !widget.ltr,
                    enableSuggestions: !widget.obscureText && !widget.ltr,
                    keyboardType: widget.keyboardType,
                    autofillHints: widget.autofillHints,
                    textInputAction: widget.textInputAction,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    onSubmitted: widget.onSubmitted,
                    onChanged: (v) {
                      state.didChange(v);
                      widget.onChanged?.call(v);
                    },
                    style: PlengoType.body.copyWith(color: ink, height: 1.3),
                    cursorColor: bad ? PlengoColors.redStrong : s.action,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: bad ? PlengoColors.red.soft : s.card,
                      constraints: const BoxConstraints(minHeight: PlengoSpace.button),
                      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 15),
                      border: border(s.line),
                      enabledBorder: border(bad ? PlengoColors.redStrong : s.line),
                      focusedBorder: border(bad ? PlengoColors.redStrong : s.action),
                      disabledBorder: border(s.line),
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              tooltip: _hidden ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                              onPressed: () => setState(() => _hidden = !_hidden),
                              icon: Icon(
                                _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: bad ? PlengoColors.ink : s.mute,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (error != null)
              FieldErrorText(message: error.message, recovery: error.recovery)
            else if (widget.hint != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 6),
                child: Text(widget.hint!, style: PlengoType.caption.copyWith(color: s.mute)),
              ),
          ],
        );
      },
    );
  }
}

/// A form-level error (network, rate limit…): red-soft card with an alert icon and the Arabic message.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(14),
        decoration: BoxDecoration(color: PlengoColors.red.soft, borderRadius: BorderRadius.circular(PlengoRadius.row)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_rounded, color: PlengoColors.red.ink, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message!, style: PlengoType.sub.copyWith(color: PlengoColors.red.ink, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title 26/700 and a mute subtitle at the top of an auth form.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, this.subtitle, this.center = false});

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: align,
            style: PlengoType.title.copyWith(color: s.ink),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: align,
            style: PlengoType.sub.copyWith(color: s.mute),
          ),
      ],
    );
  }
}

/// A text link in the action colour with a 48 dp target.
class AuthLink extends StatelessWidget {
  const AuthLink({super.key, required this.label, required this.onPressed, this.alignment});

  final String label;
  final VoidCallback? onPressed;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: s.action,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
        textStyle: PlengoType.buttonSmall,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
    return alignment == null ? button : Align(alignment: alignment!, child: button);
  }
}

/// Back to the previous screen, or to login when the auth screen was opened directly (e.g. by a link).
void authBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.login);
  }
}

/// App bar + width-capped scrolling form for register, verify and the password screens.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({super.key, required this.child, this.title, this.onBack});

  final String? title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PlengoBackButton(onPressed: onBack ?? () => authBack(context)),
        leadingWidth: kPlengoLeadingWidth,
        title: title == null ? null : Text(title!),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 28),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
          ),
        ),
      ),
    );
  }
}

/// V-Login: a yellow band with the colour logo and decorative circles; the form sits on an off-white
/// panel that overlaps the band with a 28 radius.
class AuthBandScaffold extends StatelessWidget {
  const AuthBandScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final top = MediaQuery.paddingOf(context).top;
    Widget blob(double size, Color color) => ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    return Scaffold(
      backgroundColor: s.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRect(
              child: ColoredBox(
                color: PlengoColors.yellow.base,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(20, top + 32, 20, 60),
                      // 170 wide (the wordmark is 960 × 348).
                      child: const Center(child: BrandLogo(height: 62, onBrand: true)),
                    ),
                    PositionedDirectional(
                      top: -30,
                      end: -20,
                      child: blob(90, PlengoColors.orange.base.withValues(alpha: 0.9)),
                    ),
                    PositionedDirectional(bottom: 44, start: 28, child: blob(40, PlengoColors.pink.base)),
                    PositionedDirectional(top: top + 22, start: 60, child: blob(22, PlengoColors.green.base)),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                decoration: BoxDecoration(
                  color: s.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(PlengoRadius.hero)),
                ),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 0),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
