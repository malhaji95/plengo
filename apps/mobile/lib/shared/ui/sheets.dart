import 'package:flutter/material.dart';

import 'buttons.dart';
import 'tokens.dart';

/// Opens a redesign bottom sheet: card background, 28 top radius, scrim rgba(20,20,20,.45), a 40 × 5
/// drag handle, 20 padding and a safe-area bottom. [builder] builds the content under the handle.
Future<T?> showPlengoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  final s = context.surface;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    showDragHandle: false,
    backgroundColor: s.card,
    barrierColor: PlengoColors.scrim,
    sheetAnimationStyle: AnimationStyle(
      duration: PlengoMotion.of(context, PlengoMotion.sheet),
      reverseDuration: PlengoMotion.of(context, const Duration(milliseconds: 200)),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
    ),
    builder: (context) => PlengoSheet(title: title, child: builder(context)),
  );
}

/// The body of a redesign sheet: drag handle, optional title (18/700) and scrollable content that
/// moves above the keyboard.
class PlengoSheet extends StatelessWidget {
  const PlengoSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: s.line, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (title != null) ...[
                Semantics(
                  header: true,
                  child: Text(title!, style: PlengoType.section.copyWith(color: s.ink)),
                ),
                const SizedBox(height: 10),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// A confirmation sheet body (exit practice/exam, delete): an icon in a soft circle, title, text, a
/// primary action and a ghost action. Pops `true` for [primaryLabel] and `false` for [secondaryLabel].
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.primaryLabel,
    this.message,
    this.icon,
    this.hue = PlengoColors.blue,
    this.secondaryLabel,
    this.primaryVariant = PlengoButtonVariant.primary,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final PlengoHue hue;
  final String primaryLabel;
  final String? secondaryLabel;
  final PlengoButtonVariant primaryVariant;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: hue.soft, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: hue.ink),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: PlengoType.section.copyWith(color: s.ink),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: PlengoType.sub.copyWith(color: s.mute),
          ),
        ],
        const SizedBox(height: 16),
        PlengoButton(label: primaryLabel, variant: primaryVariant, onPressed: () => Navigator.pop(context, true)),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 8),
          PlengoButton(
            label: secondaryLabel!,
            variant: PlengoButtonVariant.ghost,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ],
    );
  }
}

/// Shows a [ConfirmSheet]: `true` = primary, `false` = secondary, `null` = dismissed.
Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String primaryLabel,
  String? message,
  IconData? icon,
  PlengoHue hue = PlengoColors.blue,
  String? secondaryLabel,
  PlengoButtonVariant primaryVariant = PlengoButtonVariant.primary,
}) => showPlengoSheet<bool>(
  context: context,
  builder: (_) => ConfirmSheet(
    title: title,
    message: message,
    icon: icon,
    hue: hue,
    primaryLabel: primaryLabel,
    secondaryLabel: secondaryLabel,
    primaryVariant: primaryVariant,
  ),
);
