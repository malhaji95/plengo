import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Arabic answer normalization, version 1 (spec §14.4): the Dart port of
/// `packages/arabic-normalizer`, used to grade written answers offline (§22.6). Both must pass the
/// fixtures in `packages/arabic-normalizer/fixtures`.
abstract final class ArabicNormalizer {
  /// Must equal the server's `NORMALIZATION_VERSION`; packs with another version grade online.
  static const version = 1;

  static final _tatweel = RegExp('ـ');
  static final _diacritics = RegExp('[ً-ْٰ]');
  static final _alefForms = RegExp('[أإآٱ]');
  static final _latin = RegExp(r'\p{Script=Latin}', unicode: true);
  static final _spaces = RegExp(r'\s+');
  static const _punctuation = {
    '.',
    ',',
    '،',
    '؛',
    ';',
    ':',
    '!',
    '?',
    '؟',
    '"',
    "'",
    '«',
    '»',
    '(',
    ')',
    '-',
    '_',
    '/',
  };

  static bool _isDigit(String? ch) => ch != null && ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0;

  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in unorm.nfkc(input).runes) {
      var ch = String.fromCharCode(rune);
      if (rune >= 0x0660 && rune <= 0x0669) ch = '${rune - 0x0660}';
      if (rune >= 0x06F0 && rune <= 0x06F9) ch = '${rune - 0x06F0}';
      buffer.write(ch);
    }
    final s = buffer
        .toString()
        .replaceAll(_tatweel, '')
        .replaceAll(_diacritics, '')
        .replaceAll(_alefForms, 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('٫', '.')
        .replaceAllMapped(_latin, (m) => m[0]!.toLowerCase());

    // Punctuation becomes a space, except `.` or `,` between two digits (kept as a decimal `.`).
    final chars = s.runes.map(String.fromCharCode).toList();
    final out = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];
      if ((ch == '.' || ch == ',') &&
          _isDigit(i > 0 ? chars[i - 1] : null) &&
          _isDigit(i + 1 < chars.length ? chars[i + 1] : null)) {
        out.write('.');
      } else if (_punctuation.contains(ch)) {
        out.write(' ');
      } else {
        out.write(ch);
      }
    }
    return out.toString().replaceAll(_spaces, ' ').trim();
  }

  /// Correct when the normalized input equals any accepted answer's normalized form.
  static bool matches(String input, Iterable<String> acceptedNormalized) {
    final normalized = normalize(input);
    return normalized.isNotEmpty && acceptedNormalized.contains(normalized);
  }
}
