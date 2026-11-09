import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/shared/text/bidi.dart';

/// `⟨…⟩` stands for a left-to-right isolate, so the expectations stay readable.
String iso(String s) => s.replaceAll('⟨', '\u2066').replaceAll('⟩', '\u2069');

void main() {
  test('isolates LTR runs in Arabic text', () {
    expect(isolateLtr('بسرعة 20 m/s لمدة 5 s.'), 'بسرعة \u206620 m/s\u2069 لمدة \u20665 s\u2069.');
    expect(isolateLtr('100 m'), '\u2066100 m\u2069');
    expect(isolateLtr('F = m × a = 2 × 1.75 = 3.5 N'), '\u2066F = m × a = 2 × 1.75 = 3.5 N\u2069');
    expect(isolateLtr('الأوم'), 'الأوم');
    expect(isolateLtr(''), '');
  });

  group('mixed Arabic and formulas keep the formula in its written order', () {
    final cases = {
      'إذا كان f(x) = x^2 + 3x فأوجد المشتقة': 'إذا كان ⟨f(x) = x^2 + 3x⟩ فأوجد المشتقة',
      'أوجد قيمة f(x) = x^2 + 3x عندما x = 2.': 'أوجد قيمة ⟨f(x) = x^2 + 3x⟩ عندما ⟨x = 2⟩.',
      'حل المعادلة (x + 1)^2 = 9': 'حل المعادلة ⟨(x + 1)^2 = 9⟩',
      'المشتق f\'(x) = 2x + 3، ثم احسب f\'(0)': 'المشتق ⟨f\'(x) = 2x + 3⟩، ثم احسب ⟨f\'(0)⟩',
      'درجة الحرارة -5 °C صباحاً': 'درجة الحرارة ⟨-5 °C⟩ صباحاً',
      'بسّط -(2x - 4) ثم √16 + |x|': 'بسّط ⟨-(2x - 4)⟩ ثم ⟨√16 + |x|⟩',
      'نسبة النجاح 50% من الطلاب': 'نسبة النجاح ⟨50%⟩ من الطلاب',
      'زاوية 30° في المثلث': 'زاوية ⟨30°⟩ في المثلث',
      'المساحة πr² = 3.14 × 2²؟': 'المساحة ⟨πr² = 3.14 × 2²⟩؟',
      'قيمة sin(30°) = 0.5 دائماً': 'قيمة ⟨sin(30°) = 0.5⟩ دائماً',
      'المصفوفة [1, 2; 3, 4] مربعة': 'المصفوفة ⟨[1, 2; 3, 4]⟩ مربعة',
      'اختر «x > 3» أو «x ≤ -1»': 'اختر «⟨x > 3⟩» أو «⟨x ≤ -1⟩»',
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test(input, () => expect(isolateLtr(input), iso(expected)));
    }
  });

  test('brackets opened or closed in the Arabic stay outside the run', () {
    expect(isolateLtr('(انظر الشكل 3)'), iso('(انظر الشكل ⟨3⟩)'));
    expect(isolateLtr('الجواب (x = 4)'), iso('الجواب ⟨(x = 4)⟩'));
    expect(isolateLtr('المعادلة (1'), iso('المعادلة (⟨1⟩'));
  });

  test('line breaks end a run', () {
    expect(isolateLtr('x = 1\ny = 2'), iso('⟨x = 1⟩\n⟨y = 2⟩'));
  });

  test('is idempotent: existing isolates are left alone', () {
    const input = 'إذا كان f(x) = x^2 + 3x فإن f(2) = 10';
    final once = isolateLtr(input);
    expect(isolateLtr(once), once);
    expect(isolateLtr('نسبة ${percent(40)} تقريباً'), 'نسبة \u206640%\u2069 تقريباً');
  });

  testWidgets('a formula inside Arabic lays out in its written order', (tester) async {
    for (final formula in ['f(x) = x^2 + 3x', "f'(x) = (x + 1)^2", '-(2x - 4)']) {
      final painter = TextPainter(
        text: TextSpan(text: isolateLtr('إذا كان $formula فأوجد'), style: const TextStyle(fontSize: 20)),
        textDirection: TextDirection.rtl,
      )..layout();
      double x(int offset) => painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dx;
      // Inside the isolate each character of the formula sits to the right of the one before it.
      final first = 'إذا كان '.length + 1; // after the LRI
      final positions = [for (var i = 0; i < formula.length; i++) x(first + i)];
      for (var i = 1; i < positions.length; i++) {
        expect(positions[i], greaterThanOrEqualTo(positions[i - 1]), reason: 'character $i of «$formula»');
      }
      painter.dispose();
    }
  });

  test('percent keeps the sign after the number', () {
    expect(percent(67), '\u206667%\u2069');
  });
}
