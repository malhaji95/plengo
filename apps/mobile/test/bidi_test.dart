import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/shared/text/bidi.dart';

void main() {
  test('isolates LTR runs in Arabic text', () {
    expect(isolateLtr('بسرعة 20 m/s لمدة 5 s.'), 'بسرعة \u206620 m/s\u2069 لمدة \u20665 s\u2069.');
    expect(isolateLtr('100 m'), '\u2066100 m\u2069');
    expect(isolateLtr('F = m × a = 2 × 1.75 = 3.5 N'), '\u2066F = m × a = 2 × 1.75 = 3.5 N\u2069');
    expect(isolateLtr('الأوم'), 'الأوم');
  });

  test('percent keeps the sign after the number', () {
    expect(percent(67), '\u206667%\u2069');
  });
}
