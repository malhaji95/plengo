import 'package:flutter/material.dart';

/// Plengo redesign v2 design tokens (docs/redesign/DESIGN_SPEC.md §1–§3, tokens.json).
///
/// Every colour pair here is one the spec lists: text on a soft background uses that hue's [PlengoHue.ink];
/// white text only sits on blue `#0074B4` or strong red `#C63B3B`; other fills take dark ink `#1B1B1B`.

/// One of the six logo hues with its tints.
@immutable
class PlengoHue {
  const PlengoHue(this.name, this.base, this.soft, this.ink, {Color? shadow, Color? fill, this.whiteOnFill = false})
    : _shadow = shadow,
      _fill = fill;

  /// Stable token name: yellow, blue, green, red, orange or pink.
  final String name;

  /// The bright colour of the logo.
  final Color base;

  /// Pale background tint; text and icons on it use [ink].
  final Color soft;

  /// Dark shade for text and icons on [soft] (≥ 4.5:1).
  final Color ink;

  final Color? _shadow;
  final Color? _fill;

  /// Whether text and icons on [fill] are white (blue and red); otherwise dark ink.
  final bool whiteOnFill;

  /// The 3D bottom shadow under a [base]/[fill] surface (buttons, path nodes).
  Color get shadow => _shadow ?? ink;

  /// The solid fill behind content: [base], except red uses its strong shade so white text passes.
  Color get fill => _fill ?? base;

  /// Text and icon colour on [fill].
  Color get onFill => whiteOnFill ? Colors.white : PlengoColors.ink;

  @override
  String toString() => 'PlengoHue($name)';
}

abstract final class PlengoColors {
  static const yellow = PlengoHue(
    'yellow',
    Color(0xFFFFD62C),
    Color(0xFFFFF4C2),
    Color(0xFF6B5200),
    shadow: Color(0xFFD9AF00),
  );
  static const blue = PlengoHue(
    'blue',
    Color(0xFF0074B4),
    Color(0xFFE3F1FA),
    Color(0xFF005E92),
    shadow: Color(0xFF005E92),
    whiteOnFill: true,
  );
  static const green = PlengoHue(
    'green',
    Color(0xFF1FCD33),
    Color(0xFFE3F8E6),
    Color(0xFF157A22),
    shadow: Color(0xFF15A126),
  );
  static const red = PlengoHue(
    'red',
    Color(0xFFE54E4E),
    Color(0xFFFDE8E8),
    Color(0xFFB42323),
    shadow: Color(0xFF8E2626),
    fill: redStrong,
    whiteOnFill: true,
  );
  static const orange = PlengoHue('orange', Color(0xFFF99A2C), Color(0xFFFEEEDB), Color(0xFF9A5205));
  static const pink = PlengoHue('pink', Color(0xFFE3A4E8), Color(0xFFF7E6F9), Color(0xFF7B2F83));

  /// Red fill behind white text (danger buttons, "wrong" badges, «مرة أخرى»).
  static const redStrong = Color(0xFFC63B3B);

  /// Six hues for subjects and personal decks, in picker order.
  static const all = [yellow, blue, green, red, orange, pink];

  /// Dark text on bright fills and on every soft background.
  static const ink = Color(0xFF1B1B1B);

  /// Bottom-sheet and dialog scrim: rgba(20,20,20,.45).
  static const scrim = Color(0x73141414);

  /// The lighter blue circle decorating the hero card.
  static const heroBlob = Color(0xFF1A86C2);

  /// Hue by token name; unknown names fall back to blue.
  static PlengoHue byName(String name) => all.firstWhere((h) => h.name == name, orElse: () => blue);
}

/// Stable subject colour (DECISIONS #11): FNV-1a of the id picks one of the six hues, the same on every
/// platform and run, so a subject keeps its colour on Home, Subjects, its header and Stats.
PlengoHue subjectHue(String id) {
  var hash = 0x811C9DC5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return PlengoColors.all[hash % PlengoColors.all.length];
}

/// Neutral surfaces for light and dark mode (spec §2).
@immutable
class PlengoSurface extends ThemeExtension<PlengoSurface> {
  const PlengoSurface({
    required this.brightness,
    required this.background,
    required this.card,
    required this.ink,
    required this.mute,
    required this.line,
    required this.track,
    required this.action,
    required this.onAction,
    required this.actionShadow,
    required this.actionSoft,
    required this.nav,
  });

  final Brightness brightness;

  /// Screen background (#FAF8F3 / #151515).
  final Color background;

  /// Cards, sheets, inputs (#FFFFFF / #1F1F1F).
  final Color card;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color mute;

  /// Hairlines, borders, dividers.
  final Color line;

  /// Skeleton blocks, progress tracks, disabled buttons.
  final Color track;

  /// Primary buttons and links (#0074B4 / #5CB8EE).
  final Color action;

  /// Text on [action] (white / ink).
  final Color onAction;

  /// 3D shadow under primary buttons.
  final Color actionShadow;

  /// Pale action tint for selected rows on the neutral surface.
  final Color actionSoft;

  /// Bottom navigation background.
  final Color nav;

  bool get isDark => brightness == Brightness.dark;

  static const light = PlengoSurface(
    brightness: Brightness.light,
    background: Color(0xFFFAF8F3),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1B1B1B),
    mute: Color(0xFF5E5A52),
    line: Color(0xFFECE7DC),
    track: Color(0xFFEFEAE0),
    action: Color(0xFF0074B4),
    onAction: Color(0xFFFFFFFF),
    actionShadow: Color(0xFF005E92),
    actionSoft: Color(0xFFE3F1FA),
    nav: Color(0xFFFFFFFF),
  );

  static const dark = PlengoSurface(
    brightness: Brightness.dark,
    background: Color(0xFF151515),
    card: Color(0xFF1F1F1F),
    ink: Color(0xFFF2F2F2),
    mute: Color(0xFFB5B0A6),
    line: Color(0xFF2E2E2E),
    track: Color(0xFF2A2A2A),
    action: Color(0xFF5CB8EE),
    onAction: Color(0xFF1B1B1B),
    actionShadow: Color(0xFF2B7FAF),
    actionSoft: Color(0xFF16303F),
    nav: Color(0xFF1B1B1B),
  );

  @override
  PlengoSurface copyWith({
    Brightness? brightness,
    Color? background,
    Color? card,
    Color? ink,
    Color? mute,
    Color? line,
    Color? track,
    Color? action,
    Color? onAction,
    Color? actionShadow,
    Color? actionSoft,
    Color? nav,
  }) => PlengoSurface(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    card: card ?? this.card,
    ink: ink ?? this.ink,
    mute: mute ?? this.mute,
    line: line ?? this.line,
    track: track ?? this.track,
    action: action ?? this.action,
    onAction: onAction ?? this.onAction,
    actionShadow: actionShadow ?? this.actionShadow,
    actionSoft: actionSoft ?? this.actionSoft,
    nav: nav ?? this.nav,
  );

  @override
  PlengoSurface lerp(ThemeExtension<PlengoSurface>? other, double t) {
    if (other is! PlengoSurface) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return PlengoSurface(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      card: l(card, other.card),
      ink: l(ink, other.ink),
      mute: l(mute, other.mute),
      line: l(line, other.line),
      track: l(track, other.track),
      action: l(action, other.action),
      onAction: l(onAction, other.onAction),
      actionShadow: l(actionShadow, other.actionShadow),
      actionSoft: l(actionSoft, other.actionSoft),
      nav: l(nav, other.nav),
    );
  }
}

/// Brand roles (tokens.json `roles`): which hue carries which job, plus the subject palette.
@immutable
class PlengoBrand extends ThemeExtension<PlengoBrand> {
  const PlengoBrand({this.subjectPalette = PlengoColors.all});

  /// Hues subjects and decks are drawn from, in picker order.
  final List<PlengoHue> subjectPalette;

  PlengoHue get primaryAction => PlengoColors.blue;
  PlengoHue get brandMoment => PlengoColors.yellow;
  PlengoHue get correct => PlengoColors.green;
  PlengoHue get wrong => PlengoColors.red;
  PlengoHue get streak => PlengoColors.orange;
  PlengoHue get skipped => PlengoColors.orange;
  PlengoHue get flagged => PlengoColors.orange;
  PlengoHue get myDecks => PlengoColors.pink;
  PlengoHue get teachers => PlengoColors.pink;
  PlengoHue get locked => PlengoColors.red;
  PlengoHue get free => PlengoColors.green;
  PlengoHue get dailyGoal => PlengoColors.green;

  /// The stable colour of a subject (or deck) by id.
  PlengoHue subject(String id) => subjectHue(id);

  static const standard = PlengoBrand();

  @override
  PlengoBrand copyWith({List<PlengoHue>? subjectPalette}) =>
      PlengoBrand(subjectPalette: subjectPalette ?? this.subjectPalette);

  @override
  PlengoBrand lerp(ThemeExtension<PlengoBrand>? other, double t) => t < 0.5 ? this : (other as PlengoBrand? ?? this);
}

abstract final class PlengoRadius {
  static const card = 24.0,
      hero = 28.0,
      row = 20.0,
      button = 18.0,
      buttonSmall = 14.0,
      option = 18.0,
      iconTile = 14.0,
      sheetTop = 28.0,
      flashcard = 26.0,
      iconButton = 16.0,
      input = 16.0,
      pill = 999.0;
}

abstract final class PlengoSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 24.0;
  static const screen = 20.0, section = 16.0, cardPadding = 16.0, heroPadding = 20.0, listGap = 10.0;
  static const minTouch = 48.0, button = 54.0, buttonSmall = 48.0, option = 62.0, row = 64.0;
  static const navPillWidth = 58.0, navPillHeight = 32.0, railRow = 52.0;
  static const pathNode = 76.0, pathNodeCurrent = 84.0, examGridCell = 48.0;
  static const railBreakpoint = 600.0, contentMaxWide = 720.0, railWidth = 240.0;
}

abstract final class PlengoType {
  static const family = 'MontserratArabic';
  static TextStyle _s(double size, FontWeight w, [double? h]) =>
      TextStyle(fontFamily: family, fontSize: size, fontWeight: w, height: h);
  static final display = _s(30, FontWeight.w700, 1.2);
  static final title = _s(26, FontWeight.w700, 1.45);
  static final question = _s(21, FontWeight.w700, 1.7);
  static final section = _s(18, FontWeight.w700, 1.5);
  static final rowTitle = _s(15, FontWeight.w700, 1.5);
  static final body = _s(16, FontWeight.w500, 1.6);
  static final sub = _s(14, FontWeight.w400, 1.8);
  static final button = _s(16, FontWeight.w700);
  static final buttonSmall = _s(14, FontWeight.w700);
  static final caption = _s(12, FontWeight.w400, 1.6);
  static final chip = _s(12, FontWeight.w700);
  static final navLabel = _s(11, FontWeight.w600);
}

abstract final class PlengoMotion {
  static const press = Duration(milliseconds: 100),
      flip = Duration(milliseconds: 500),
      sheet = Duration(milliseconds: 250),
      feedback = Duration(milliseconds: 200),
      progress = Duration(milliseconds: 300),
      celebrate = Duration(milliseconds: 600);

  /// [d], or zero when the system asks for reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : d;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Card shadow (light only): `0 1 0 line, 0 6 18 rgba(60,45,10,.05)`.
List<BoxShadow> plengoCardShadow(PlengoSurface s) => s.isDark
    ? const []
    : [
        BoxShadow(color: s.line, offset: const Offset(0, 1)),
        const BoxShadow(color: Color(0x0D3C2D0A), offset: Offset(0, 6), blurRadius: 18),
      ];

/// Short access to the tokens of the current theme.
extension PlengoThemeContext on BuildContext {
  PlengoSurface get surface =>
      Theme.of(this).extension<PlengoSurface>() ??
      (Theme.of(this).brightness == Brightness.dark ? PlengoSurface.dark : PlengoSurface.light);

  PlengoBrand get brand => Theme.of(this).extension<PlengoBrand>() ?? PlengoBrand.standard;
}
