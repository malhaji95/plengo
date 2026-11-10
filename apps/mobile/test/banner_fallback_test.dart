import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/app/theme.dart';
import 'package:plengo/features/home/home_providers.dart';
import 'package:plengo/shared/ui/ui.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('a banner that cannot load shows its title in white on blue (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(width: 360, height: 200, child: BannerFallback(title: 'ابدأ مراجعة الفيزياء')),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('ابدأ مراجعة الفيزياء'));
      expect(text.style?.color, Colors.white);
      final box = tester.widget<ColoredBox>(
        find.ancestor(of: find.text('ابدأ مراجعة الفيزياء'), matching: find.byType(ColoredBox)).first,
      );
      expect(box.color, PlengoColors.blue.base);
    });
  }
}
