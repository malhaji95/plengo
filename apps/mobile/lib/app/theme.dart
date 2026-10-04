import 'package:flutter/material.dart';

/// Plengo brand colours (design/brand/plengo-logo.pdf; sampled from the master artwork).
///
/// The logo letters use these exact values. In the interface, blue carries actions and links (in
/// the slightly deeper [action] shade so white labels pass WCAG AA), and the bright colours are
/// fills behind dark [ink] text — never white text, never text on white.
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

  /// [blue] lightened until ink text reads on it (10:1); the blue member of [tiles].
  static const sky = Color(0xFF8FD0F2);

  /// The logo's letter colours in order, for decorative accents (charts, confetti).
  static const accents = [pink, yellow, red, green, blue, orange];

  /// Fills for content tiles (subject cards). Every one carries [ink] text at 7.9:1 or better.
  static const tiles = [yellow, sky, green, orange, pink];

  /// Pale tints of the logo colours behind icons and status rows; ink text reads at 12:1 or better.
  static const tintYellow = Color(0xFFFFF1B8);
  static const tintBlue = Color(0xFFCDEBFA);
  static const tintGreen = Color(0xFFD9F7DD);
  static const tintOrange = Color(0xFFFDE3C2);
  static const tintPink = Color(0xFFF6DDF8);
  static const tintRed = Color(0xFFFBD5D5);

  /// Status colours that keep 4.5:1 for text and icons on light and dark surfaces.
  static Color success(Brightness b) => b == Brightness.dark ? const Color(0xFF6EE07A) : const Color(0xFF13852A);
  static Color warning(Brightness b) => b == Brightness.dark ? const Color(0xFFFFC266) : const Color(0xFF9A5B00);
}

/// Every screen reads colours and text styles from here, so the brand is a one-file change.
abstract final class AppTheme {
  static const seed = BrandColors.blue;

  /// Body text and long educational content (questions, explanations).
  static const fontFamily = 'IBMPlexSansArabic';

  /// Major headings and onboarding titles only: display and headline styles, and app bar titles.
  /// One weight (Bold) is bundled to keep the web first load small (§34.3).
  static const headingFont = 'NotoKufiArabic';

  static const radius = 20.0;

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
          secondaryContainer: dark ? const Color(0xFF4A3F00) : BrandColors.tintYellow,
          onSecondaryContainer: dark ? const Color(0xFFFFE680) : BrandColors.ink,
          tertiary: BrandColors.success(brightness),
          error: dark ? const Color(0xFFFF8A80) : BrandColors.error,
          surface: dark ? const Color(0xFF14171C) : Colors.white,
          surfaceContainerLowest: dark ? const Color(0xFF0F1216) : const Color(0xFFF5F7FB),
        );
    final background = scheme.surfaceContainerLowest;
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: fontFamily);
    final text = base.textTheme;
    TextStyle? heading(TextStyle? s, FontWeight w) => s?.copyWith(fontFamily: headingFont, fontWeight: w, height: 1.5);
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final border = BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? 0.5 : 0.6));
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text.copyWith(
        displayLarge: heading(text.displayLarge, FontWeight.w700),
        displayMedium: heading(text.displayMedium, FontWeight.w700),
        displaySmall: heading(text.displaySmall, FontWeight.w700),
        headlineLarge: heading(text.headlineLarge, FontWeight.w700),
        headlineMedium: heading(text.headlineMedium, FontWeight.w700),
        headlineSmall: heading(text.headlineSmall, FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: heading(text.titleLarge, FontWeight.w700)?.copyWith(color: scheme.onSurface, fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: border),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 10,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: border),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: border),
        filled: true,
        fillColor: scheme.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: rounded,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: border,
        backgroundColor: scheme.surface,
        selectedColor: scheme.secondaryContainer,
        showCheckmark: true,
        checkmarkColor: scheme.onSecondaryContainer,
        labelStyle: TextStyle(fontFamily: fontFamily, color: scheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.secondaryContainer,
          selectedForegroundColor: scheme.onSecondaryContainer,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 8,
        borderRadius: BorderRadius.circular(8),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      expansionTileTheme: const ExpansionTileThemeData(shape: Border(), collapsedShape: Border()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
    );
  }
}
