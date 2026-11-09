import 'package:flutter/material.dart';

import '../shared/ui/tokens.dart';

/// Older names for the brand colours, kept so existing screens compile while they move to
/// [PlengoColors] / [PlengoSurface] (docs/redesign). Values follow the redesign tokens.
///
/// Blue carries actions and links; the bright colours are fills behind dark [ink] text, never
/// white text, never text on white.
abstract final class BrandColors {
  static const yellow = Color(0xFFFFD62C);
  static const pink = Color(0xFFE3A4E8);
  static const red = Color(0xFFE54E4E);
  static const green = Color(0xFF1FCD33);
  static const blue = Color(0xFF0074B4);
  static const orange = Color(0xFFF99A2C);
  static const ink = PlengoColors.ink;

  /// Primary actions on light surfaces (5:1 with white).
  static const action = Color(0xFF0074B4);

  /// Primary actions in dark mode (takes ink text).
  static const actionDark = Color(0xFF5CB8EE);

  /// Red text on light surfaces (red ink).
  static const error = Color(0xFFB42323);

  /// Light blue fill that carries ink text; the blue member of [tiles].
  static const sky = Color(0xFF8FD0F2);

  /// The logo's letter colours in order, for decorative accents (charts, confetti).
  static const accents = [pink, yellow, red, green, blue, orange];

  /// Fills for content tiles. Every one carries [ink] text.
  static const tiles = [yellow, sky, green, orange, pink];

  /// Soft tints of the logo colours (redesign "soft"); ink text reads on all of them.
  static const tintYellow = Color(0xFFFFF4C2);
  static const tintBlue = Color(0xFFE3F1FA);
  static const tintGreen = Color(0xFFE3F8E6);
  static const tintOrange = Color(0xFFFEEEDB);
  static const tintPink = Color(0xFFF7E6F9);
  static const tintRed = Color(0xFFFDE8E8);

  /// Status colours that keep 4.5:1 for text and icons on light and dark surfaces.
  static Color success(Brightness b) => b == Brightness.dark ? const Color(0xFF6EE07A) : const Color(0xFF157A22);
  static Color warning(Brightness b) => b == Brightness.dark ? const Color(0xFFFFC266) : const Color(0xFF9A5205);
}

/// Light and dark [ThemeData] built from the redesign tokens ([PlengoSurface], [PlengoColors]).
abstract final class AppTheme {
  static const seed = BrandColors.blue;

  /// Montserrat Arabic (Kief Type Foundry, SIL OFL) for everything.
  static const fontFamily = PlengoType.family;
  static const headingFont = fontFamily;

  /// Default card radius of the older widgets; new code uses [PlengoRadius].
  static const radius = PlengoRadius.row;

  static ThemeData light() => _build(PlengoSurface.light);
  static ThemeData dark() => _build(PlengoSurface.dark);

  static ThemeData _build(PlengoSurface s) {
    final dark = s.isDark;
    final brightness = s.brightness;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ).copyWith(
          primary: s.action,
          onPrimary: s.onAction,
          primaryContainer: PlengoColors.blue.soft,
          onPrimaryContainer: PlengoColors.blue.ink,
          secondary: PlengoColors.yellow.base,
          onSecondary: PlengoColors.ink,
          secondaryContainer: PlengoColors.yellow.soft,
          onSecondaryContainer: PlengoColors.yellow.ink,
          tertiary: BrandColors.success(brightness),
          onTertiary: PlengoColors.ink,
          tertiaryContainer: PlengoColors.green.soft,
          onTertiaryContainer: PlengoColors.green.ink,
          error: dark ? const Color(0xFFFF8A80) : PlengoColors.red.ink,
          onError: dark ? PlengoColors.ink : Colors.white,
          errorContainer: PlengoColors.red.soft,
          onErrorContainer: PlengoColors.red.ink,
          surface: s.card,
          onSurface: s.ink,
          onSurfaceVariant: s.mute,
          outline: s.mute,
          outlineVariant: s.line,
          surfaceContainerLowest: s.background,
          surfaceContainerLow: s.card,
          surfaceContainer: s.card,
          surfaceContainerHigh: s.track,
          surfaceContainerHighest: s.track,
          surfaceTint: Colors.transparent,
          shadow: const Color(0xFF3C2D0A),
          scrim: PlengoColors.scrim,
        );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: fontFamily);
    final text = base.textTheme;
    TextStyle? bold(TextStyle? t, [double height = 1.5]) =>
        t?.copyWith(fontFamily: headingFont, fontWeight: FontWeight.w700, height: height);
    final line = BorderSide(color: s.line);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.button));
    final inputRadius = BorderRadius.circular(PlengoRadius.input);
    OutlineInputBorder inputBorder(Color c) => OutlineInputBorder(
      borderRadius: inputRadius,
      borderSide: BorderSide(color: c, width: 2),
    );
    return base.copyWith(
      scaffoldBackgroundColor: s.background,
      canvasColor: s.background,
      dividerColor: s.line,
      extensions: [s, PlengoBrand.standard],
      textTheme: text.copyWith(
        displayLarge: bold(text.displayLarge, 1.2),
        displayMedium: bold(text.displayMedium, 1.2),
        displaySmall: bold(text.displaySmall?.copyWith(fontSize: 30), 1.2),
        headlineLarge: bold(text.headlineLarge, 1.4),
        headlineMedium: bold(text.headlineMedium, 1.4),
        headlineSmall: bold(text.headlineSmall?.copyWith(fontSize: 26), 1.45),
        titleLarge: bold(text.titleLarge?.copyWith(fontSize: 20)),
        titleMedium: bold(text.titleMedium?.copyWith(fontSize: 16)),
        titleSmall: bold(text.titleSmall?.copyWith(fontSize: 14)),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.6),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 1.6),
        bodySmall: text.bodySmall?.copyWith(fontSize: 12, height: 1.6, color: s.mute),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: s.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: s.background,
        foregroundColor: s.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: headingFont, fontSize: 20, fontWeight: FontWeight.w700, color: s.ink),
      ),
      cardTheme: CardThemeData(
        color: s.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x143C2D0A),
        elevation: dark ? 0 : 1,
        margin: const EdgeInsets.only(bottom: PlengoSpace.listGap),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: dark ? line : BorderSide.none),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.row)),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 2),
        minVerticalPadding: 10,
        iconColor: s.ink,
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: s.ink),
        subtitleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, height: 1.6, color: s.mute),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: inputBorder(s.line),
        enabledBorder: inputBorder(s.line),
        focusedBorder: inputBorder(s.action),
        errorBorder: inputBorder(PlengoColors.redStrong),
        focusedErrorBorder: inputBorder(PlengoColors.redStrong),
        filled: true,
        fillColor: s.card,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(fontFamily: fontFamily, color: s.mute, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(fontFamily: fontFamily, color: s.mute, fontWeight: FontWeight.w500),
        errorStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700, color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          disabledBackgroundColor: s.track,
          disabledForegroundColor: s.mute,
          minimumSize: const Size.fromHeight(PlengoSpace.button),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PlengoColors.yellow.base,
          foregroundColor: PlengoColors.ink,
          elevation: 0,
          minimumSize: const Size(48, PlengoSpace.buttonSmall),
          shape: buttonShape,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.action,
          backgroundColor: s.card,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          side: BorderSide(color: s.action, width: 2),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.action,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.buttonSmall)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: s.ink,
          minimumSize: const Size.square(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.iconButton)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: s.line, width: 1.5),
        backgroundColor: s.card,
        selectedColor: dark ? PlengoColors.yellow.base : PlengoColors.ink,
        secondarySelectedColor: dark ? PlengoColors.yellow.base : PlengoColors.ink,
        showCheckmark: true,
        checkmarkColor: dark ? PlengoColors.ink : Colors.white,
        labelStyle: WidgetStateTextStyle.resolveWith(
          (st) => TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            color: st.contains(WidgetState.selected) ? (dark ? PlengoColors.ink : Colors.white) : s.ink,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: s.track,
          foregroundColor: s.mute,
          selectedBackgroundColor: s.card,
          selectedForegroundColor: s.ink,
          side: BorderSide(color: s.track, width: 2),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.iconButton)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.action : s.mute),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.action : null),
        checkColor: WidgetStatePropertyAll(s.onAction),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.onAction : s.mute),
        trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? s.action : s.track),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? s.action : s.mute,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.nav,
        surfaceTintColor: Colors.transparent,
        indicatorColor: PlengoColors.yellow.base,
        elevation: 0,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (st) => IconThemeData(size: 22, color: st.contains(WidgetState.selected) ? PlengoColors.ink : s.mute),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (st) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            color: st.contains(WidgetState.selected) ? s.ink : s.mute,
            fontWeight: st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: s.card,
        indicatorColor: PlengoColors.yellow.base,
        selectedIconTheme: const IconThemeData(color: PlengoColors.ink),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: s.ink,
        unselectedLabelColor: s.mute,
        indicatorColor: s.action,
        dividerColor: s.line,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.action,
        linearTrackColor: s.track,
        circularTrackColor: s.track,
        linearMinHeight: 10,
        borderRadius: BorderRadius.circular(PlengoRadius.pill),
      ),
      dividerTheme: DividerThemeData(color: s.line, thickness: 1, space: 1),
      expansionTileTheme: const ExpansionTileThemeData(shape: Border(), collapsedShape: Border()),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? s.card : PlengoColors.ink,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: dark ? s.ink : Colors.white),
        actionTextColor: PlengoColors.yellow.base,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.buttonSmall)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: PlengoColors.scrim,
        showDragHandle: true,
        dragHandleColor: s.line,
        dragHandleSize: const Size(40, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(PlengoRadius.sheetTop)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.card,
        surfaceTintColor: Colors.transparent,
        barrierColor: PlengoColors.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.card)),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: s.ink),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PlengoRadius.buttonSmall)),
      ),
    );
  }
}
