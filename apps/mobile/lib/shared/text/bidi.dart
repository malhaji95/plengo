/// Keeps numbers, units and Latin formulas left-to-right inside Arabic text (spec §25), e.g.
/// "بسرعة 20 m/s لمدة 5 s" instead of "بسرعة m/s 20 لمدة s 5", and «f(x) = x^2 + 3x» or
/// «-(x + 1)²» in their written order. Each LTR run is wrapped in a left-to-right isolate
/// (U+2066 … U+2069); the Arabic around it is untouched.
///
/// A run is the stretch between the first and the last strong LTR character (Latin or Greek letter,
/// digit, super/subscript) of a piece of text that holds no Arabic letter, Arabic punctuation or line
/// break. Everything between them (operators, brackets, primes, spaces) belongs to the formula. It
/// then takes in the signs and opening brackets written right before it («-3», «(x + 1)», «√2») and
/// the closing marks right after it («f(x)», «50%», «30°», «f'», «n!»). Brackets that open or close
/// outside the run («(انظر الشكل 3)») stay with the Arabic. Sentence punctuation at its end («5 s.»)
/// stays outside. Text already inside an isolate is kept as it is, so calling this twice is safe.
String isolateLtr(String text) {
  if (text.isEmpty) return text;
  final out = StringBuffer();
  final segment = StringBuffer();
  void flush() {
    if (segment.isEmpty) return;
    out.write(_isolateSegment(segment.toString()));
    segment.clear();
  }

  final units = text.runes.toList();
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    if (c == _lri || c == _rli || c == _fsi) {
      flush();
      // Copy an existing isolate verbatim, nested ones included.
      var depth = 0;
      for (; i < units.length; i++) {
        final d = units[i];
        out.writeCharCode(d);
        if (d == _lri || d == _rli || d == _fsi) depth++;
        if (d == _pdi && --depth == 0) break;
      }
      continue;
    }
    if (_breaksRun(c)) {
      flush();
      out.writeCharCode(c);
    } else {
      segment.writeCharCode(c);
    }
  }
  flush();
  return out.toString();
}

/// "67%" as one left-to-right run, so the sign stays after the number in Arabic text.
String percent(int value) => '\u2066$value%\u2069';

const _lri = 0x2066, _rli = 0x2067, _fsi = 0x2068, _pdi = 0x2069;

/// Wraps the LTR run of a piece of text that holds no Arabic.
String _isolateSegment(String segment) {
  final c = segment.runes.toList();
  var start = c.indexWhere(_isStrongLtr);
  if (start < 0) return segment;
  var end = c.lastIndexWhere(_isStrongLtr) + 1;
  while (start > 0 && _leading.contains(c[start - 1])) {
    start--;
  }
  while (end < c.length && _trailing.contains(c[end])) {
    end++;
  }
  // Brackets that the run does not close (or open) belong to the Arabic around it.
  while (true) {
    final run = c.sublist(start, end);
    if (start < end && _openers.contains(run.first) && !_closes(run, 0)) {
      start++;
    } else if (start < end && _closers.containsKey(run.last) && !_opens(run, run.length - 1)) {
      end--;
    } else {
      break;
    }
  }
  while (start < end && c[start] == 0x20) {
    start++;
  }
  while (end > start && c[end - 1] == 0x20) {
    end--;
  }
  if (start >= end) return segment;
  return '${String.fromCharCodes(c, 0, start)}\u2066${String.fromCharCodes(c, start, end)}\u2069'
      '${String.fromCharCodes(c, end)}';
}

/// Whether the opening bracket at [i] is closed inside [run].
bool _closes(List<int> run, int i) {
  final open = run[i];
  var depth = 0;
  for (var j = i; j < run.length; j++) {
    if (run[j] == open) depth++;
    if (_closers[run[j]] == open && --depth == 0) return true;
  }
  return false;
}

/// Whether the closing bracket at [i] was opened inside [run].
bool _opens(List<int> run, int i) {
  final open = _closers[run[i]]!;
  var depth = 0;
  for (var j = i; j >= 0; j--) {
    if (run[j] == run[i]) depth++;
    if (run[j] == open && --depth == 0) return true;
  }
  return false;
}

bool _isStrongLtr(int c) =>
    (c >= 0x30 && c <= 0x39) || // 0-9
    (c >= 0x41 && c <= 0x5A) || // A-Z
    (c >= 0x61 && c <= 0x7A) || // a-z
    c == 0xB2 ||
    c == 0xB3 ||
    c == 0xB9 || // ² ³ ¹
    (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7) || // Latin letters, not × ÷
    (c >= 0x370 && c <= 0x3FF) || // Greek (π, θ, Δ, λ …)
    (c >= 0x2070 && c <= 0x209F) || // superscripts and subscripts
    c == 0x221E; // ∞

/// Arabic letters, digits and punctuation (، ؛ ؟), guillemets and line breaks end a run.
bool _breaksRun(int c) =>
    (c >= 0x0600 && c <= 0x06FF) ||
    (c >= 0x0750 && c <= 0x077F) ||
    (c >= 0x08A0 && c <= 0x08FF) ||
    (c >= 0xFB50 && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF) ||
    c == 0xAB || // «
    c == 0xBB || // »
    c == 0x0A ||
    c == 0x0D ||
    c == 0x2028 ||
    c == 0x2029;

const _openers = {0x28, 0x5B, 0x7B}; // ( [ {
const _closers = {0x29: 0x28, 0x5D: 0x5B, 0x7D: 0x7B}; // ) ] }

/// Signs and brackets written right before a formula: ( [ { - − + ± √ ∛ | $
final _leading = {..._openers, 0x2D, 0x2212, 0x2B, 0xB1, 0x221A, 0x221B, 0x7C, 0x24};

/// Marks written right after a formula: ) ] } ' ′ ″ % ‰ ° ! |
final _trailing = {..._closers.keys, 0x27, 0x2032, 0x2033, 0x25, 0x2030, 0xB0, 0x21, 0x7C};
