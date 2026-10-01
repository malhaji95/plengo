import 'package:flutter/material.dart';

/// Plengo brand colours (design/brand/plengo-logo.pdf; sampled from the master artwork).
///
/// The logo letters use these exact values. In the interface, blue carries actions and links (in
/// the slightly deeper [action] shade so white labels pass WCAG AA), and the bright colours are
/// fills behind dark text — never text on white.
abstract final class BrandColors {
  static const yellow = Color(0xFFFFD62C);
  static const pink = Color(0xFFE3A4E8);
  static const red = Color(0xFFE54E4E);
  static const green = Color(0xFF1FCD33);
  static const blue = Color(0xFF0080C6);
  static const orange = Color(0xFFF99A2C);
  static const ink = Color(0xFF1B1B1B);

  /// [blue] darkened just enough for 5:1 with white (buttons, links, selected states).
  static const action = Color(0xFF0074B4);

  /// [blue] lightened for dark mode (8:1 on the dark surface).
  static const actionDark = Color(0xFF4FB3EE);

  /// [red] darkened for error text on white.
  static const error = Color(0xFFC73B3B);

  /// The logo's letter colours in order, for decorative accents (subject cards, charts).
  static const accents = [pink, yellow, red, green, blue, orange];
}

/// Every screen reads colours and text styles from here, so the brand is a one-file change.
abstract final class AppTheme {
  static const seed = BrandColors.blue;
  static const fontFamily = 'IBMPlexSansArabic';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: dark ? BrandColors.actionDark : BrandColors.action,
          onPrimary: dark ? BrandColors.ink : Colors.white,
          secondary: BrandColors.yellow,
          onSecondary: BrandColors.ink,
          secondaryContainer: dark ? const Color(0xFF4A3F00) : const Color(0xFFFFF1B8),
          onSecondaryContainer: dark ? const Color(0xFFFFE680) : BrandColors.ink,
          tertiary: dark ? const Color(0xFF6EE07A) : const Color(0xFF13852A),
          error: dark ? const Color(0xFFFF8A80) : BrandColors.error,
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: fontFamily);
    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
