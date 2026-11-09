// Plengo redesign v2 — design tokens (starting point).
// Adapt into lib/app/theme.dart or lib/shared/ui/ to match the repo structure.
import 'package:flutter/material.dart';

class PlengoHue {
  const PlengoHue(this.base, this.soft, this.ink, [this.shadow]);
  final Color base, soft, ink;
  final Color? shadow;
}

abstract final class PlengoColors {
  static const yellow = PlengoHue(Color(0xFFFFD62C), Color(0xFFFFF4C2), Color(0xFF6B5200), Color(0xFFD9AF00));
  static const blue = PlengoHue(Color(0xFF0074B4), Color(0xFFE3F1FA), Color(0xFF005E92), Color(0xFF005E92));
  static const green = PlengoHue(Color(0xFF1FCD33), Color(0xFFE3F8E6), Color(0xFF157A22), Color(0xFF15A126));
  static const red = PlengoHue(Color(0xFFE54E4E), Color(0xFFFDE8E8), Color(0xFFB42323), Color(0xFF8E2626));
  static const redStrong = Color(0xFFC63B3B); // fill behind white text
  static const orange = PlengoHue(Color(0xFFF99A2C), Color(0xFFFEEEDB), Color(0xFF9A5205));
  static const pink = PlengoHue(Color(0xFFE3A4E8), Color(0xFFF7E6F9), Color(0xFF7B2F83));

  /// Six hues for subjects and personal decks, in picker order.
  static const all = [yellow, blue, green, red, orange, pink];

  static const ink = Color(0xFF1B1B1B);
  static const scrim = Color(0x73141414);
}

@immutable
class PlengoSurface extends ThemeExtension<PlengoSurface> {
  const PlengoSurface({
    required this.background, required this.card, required this.ink, required this.mute,
    required this.line, required this.track, required this.action, required this.onAction,
  });
  final Color background, card, ink, mute, line, track, action, onAction;

  static const light = PlengoSurface(
    background: Color(0xFFFAF8F3), card: Color(0xFFFFFFFF), ink: Color(0xFF1B1B1B), mute: Color(0xFF5E5A52),
    line: Color(0xFFECE7DC), track: Color(0xFFEFEAE0), action: Color(0xFF0074B4), onAction: Color(0xFFFFFFFF));
  static const dark = PlengoSurface(
    background: Color(0xFF151515), card: Color(0xFF1F1F1F), ink: Color(0xFFF2F2F2), mute: Color(0xFFB5B0A6),
    line: Color(0xFF2E2E2E), track: Color(0xFF2A2A2A), action: Color(0xFF5CB8EE), onAction: Color(0xFF1B1B1B));

  @override
  PlengoSurface copyWith({Color? background, Color? card, Color? ink, Color? mute, Color? line, Color? track, Color? action, Color? onAction}) =>
      PlengoSurface(background: background ?? this.background, card: card ?? this.card, ink: ink ?? this.ink, mute: mute ?? this.mute,
          line: line ?? this.line, track: track ?? this.track, action: action ?? this.action, onAction: onAction ?? this.onAction);

  @override
  PlengoSurface lerp(ThemeExtension<PlengoSurface>? other, double t) {
    if (other is! PlengoSurface) return this;
    return PlengoSurface(
      background: Color.lerp(background, other.background, t)!, card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!, mute: Color.lerp(mute, other.mute, t)!, line: Color.lerp(line, other.line, t)!,
      track: Color.lerp(track, other.track, t)!, action: Color.lerp(action, other.action, t)!, onAction: Color.lerp(onAction, other.onAction, t)!);
  }
}

abstract final class PlengoRadius {
  static const card = 24.0, hero = 28.0, row = 20.0, button = 18.0, buttonSmall = 14.0,
      option = 18.0, iconTile = 14.0, sheetTop = 28.0, flashcard = 26.0, pill = 999.0;
}

abstract final class PlengoSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 20.0, xxl = 24.0;
  static const screen = 20.0, section = 16.0, listGap = 10.0;
  static const minTouch = 48.0, button = 54.0, option = 62.0, row = 64.0;
  static const railBreakpoint = 600.0, contentMaxWide = 720.0, railWidth = 240.0;
}

abstract final class PlengoType {
  static const family = 'MontserratArabic';
  static TextStyle _s(double size, FontWeight w, [double? h]) => TextStyle(fontFamily: family, fontSize: size, fontWeight: w, height: h);
  static final display = _s(30, FontWeight.w700, 1.2);
  static final title = _s(26, FontWeight.w700, 1.45);
  static final question = _s(21, FontWeight.w700, 1.7);
  static final section = _s(18, FontWeight.w700, 1.5);
  static final rowTitle = _s(15, FontWeight.w700, 1.5);
  static final body = _s(16, FontWeight.w500, 1.6);
  static final sub = _s(14, FontWeight.w400, 1.8);
  static final button = _s(16, FontWeight.w700);
  static final caption = _s(12, FontWeight.w400, 1.6);
  static final chip = _s(12, FontWeight.w700);
  static final navLabel = _s(11, FontWeight.w600);
}

/// App font-size setting → text scale.
enum PlengoFontSize { small, normal, large }
extension PlengoFontScale on PlengoFontSize {
  double get scale => switch (this) { PlengoFontSize.small => 0.88, PlengoFontSize.normal => 1.0, PlengoFontSize.large => 1.16 };
}

abstract final class PlengoMotion {
  static const press = Duration(milliseconds: 100), flip = Duration(milliseconds: 500), sheet = Duration(milliseconds: 250),
      feedback = Duration(milliseconds: 200), progress = Duration(milliseconds: 300), celebrate = Duration(milliseconds: 600);
}
