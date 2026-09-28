/// Keeps numbers, units and Latin formulas left-to-right inside Arabic text (spec §25), e.g.
/// "بسرعة 20 m/s لمدة 5 s" instead of "بسرعة m/s 20 لمدة s 5". Each LTR run is wrapped in a
/// first-strong/left-to-right isolate (U+2066 … U+2069); the Arabic around it is untouched.
String isolateLtr(String text) => text.replaceAllMapped(_ltrRun, (m) => '\u2066${m[0]}\u2069');

final _ltrRun = RegExp(r'[A-Za-z0-9](?:[A-Za-z0-9.,/²³^×*+=\-() ]*[A-Za-z0-9²³)])?');

/// "67%" as one left-to-right run, so the sign stays after the number in Arabic text.
String percent(int value) => '\u2066$value%\u2069';
