import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/theme.dart';
import 'package:plengo/features/debug/widget_catalog_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

/// Redesign v2 shared components (docs/redesign/DESIGN_SPEC.md §4).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: Directionality(textDirection: TextDirection.rtl, child: app!),
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
        ),
      ),
    );
  }

  group('tokens and theme', () {
    test('subject colours are stable and use all six hues', () {
      expect(subjectHue('subject-math'), same(subjectHue('subject-math')));
      final used = {for (var i = 0; i < 200; i++) subjectHue('s$i').name};
      expect(used, PlengoColors.all.map((h) => h.name).toSet());
    });

    test('light and dark themes come from the tokens', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.scaffoldBackgroundColor, const Color(0xFFFAF8F3));
      expect(dark.scaffoldBackgroundColor, const Color(0xFF151515));
      expect(light.extension<PlengoSurface>(), PlengoSurface.light);
      expect(dark.extension<PlengoSurface>()!.action, const Color(0xFF5CB8EE));
      expect(light.colorScheme.primary, const Color(0xFF0074B4));
      expect(light.extension<PlengoBrand>(), isNotNull);
    });

    test('the three font sizes follow the design (0.88 / 1.0 / 1.16)', () {
      expect(AppearanceSettings.fontScales, [0.88, 1.0, 1.16]);
      expect(const AppearanceSettings(fontStep: 2).textScale, 1.16);
    });

    test('white text only on blue and strong red fills', () {
      for (final h in PlengoColors.all) {
        expect(h.onFill == Colors.white, h == PlengoColors.blue || h == PlengoColors.red, reason: h.name);
      }
      expect(PlengoColors.red.fill, PlengoColors.redStrong);
    });
  });

  group('PlengoButton', () {
    testWidgets('a tap calls onPressed; pressing moves it down and drops the shadow', (tester) async {
      var taps = 0;
      await pump(tester, PlengoButton(label: 'تحقق', onPressed: () => taps++));
      final box = find.descendant(of: find.byType(PlengoButton), matching: find.byType(AnimatedContainer));
      BoxDecoration decoration() => tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
      expect(decoration().boxShadow, hasLength(1));
      expect(tester.getSize(find.byType(PlengoButton)).height, 54);

      final gesture = await tester.startGesture(tester.getCenter(find.text('تحقق')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(decoration().boxShadow, isEmpty);
      expect(tester.widget<AnimatedContainer>(box).transform!.getTranslation().y, 4);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(decoration().boxShadow, hasLength(1));
    });

    testWidgets('disabled: track fill, no shadow, no taps, announced as disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const PlengoButton(label: 'اختر إجابة', onPressed: null));
      final box = find.descendant(of: find.byType(PlengoButton), matching: find.byType(AnimatedContainer));
      final decoration = tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
      expect(decoration.color, PlengoSurface.light.track);
      expect(decoration.boxShadow, isEmpty);
      expect(
        tester.getSemantics(find.byType(PlengoButton)),
        isSemantics(label: 'اختر إجابة', isButton: true, hasEnabledState: true, isEnabled: false),
      );
      semantics.dispose();
    });

    testWidgets('busy shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await pump(tester, PlengoButton(label: 'إرسال', busy: true, onPressed: () => taps++));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(PlengoButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('danger is strong red with white text; small is 48 high', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            PlengoButton(label: 'مرة أخرى', variant: PlengoButtonVariant.danger, onPressed: () {}),
            PlengoButton(label: 'صغير', size: PlengoButtonSize.small, onPressed: () {}),
          ],
        ),
      );
      final danger = find.descendant(
        of: find.widgetWithText(PlengoButton, 'مرة أخرى'),
        matching: find.byType(AnimatedContainer),
      );
      expect((tester.widget<AnimatedContainer>(danger).decoration! as BoxDecoration).color, PlengoColors.redStrong);
      expect(tester.widget<Text>(find.text('مرة أخرى')).style!.color, Colors.white);
      expect(tester.getSize(find.widgetWithText(PlengoButton, 'صغير')).height, 48);
    });

    testWidgets('reduced motion makes the press instant', (tester) async {
      await pump(tester, PlengoButton(label: 'تابع', onPressed: () {}), disableAnimations: true);
      final box = find.descendant(of: find.byType(PlengoButton), matching: find.byType(AnimatedContainer));
      expect(tester.widget<AnimatedContainer>(box).duration, Duration.zero);
    });
  });

  group('AnswerOption', () {
    Widget options(List<AnswerState> states, {ValueChanged<int>? onTap}) => Column(
      children: [
        for (final (i, s) in states.indexed)
          AnswerOption(index: i, text: 'خيار $i', state: s, onTap: onTap == null ? null : () => onTap(i)),
      ],
    );

    BoxDecoration decorationOf(WidgetTester tester, int i) {
      final box = find.descendant(of: find.byType(AnswerOption).at(i), matching: find.byType(AnimatedContainer));
      return tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
    }

    testWidgets('letters أ ب ج د and the selected state', (tester) async {
      final picked = <int>[];
      await pump(
        tester,
        options([AnswerState.normal, AnswerState.selected, AnswerState.normal, AnswerState.normal], onTap: picked.add),
      );
      for (final l in ['أ', 'ب', 'ج', 'د']) {
        expect(find.text(l), findsOneWidget);
      }
      expect(decorationOf(tester, 1).color, PlengoColors.blue.soft);
      expect((decorationOf(tester, 1).border! as Border).top.color, PlengoColors.blue.base);
      expect(decorationOf(tester, 0).color, PlengoSurface.light.card);
      expect(find.text(AnswerOption.correctTag), findsNothing);
      await tester.tap(find.text('خيار 2'));
      expect(picked, [2]);
      expect(tester.getSize(find.byType(AnswerOption).first).height, greaterThanOrEqualTo(62));
    });

    testWidgets('after checking: correct and wrong carry ✓/✗ tags, the rest is dimmed', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, options([AnswerState.correct, AnswerState.wrong, AnswerState.dimmed, AnswerState.dimmed]));
      expect(find.text('✓ صحيحة'), findsOneWidget);
      expect(find.text('✗ إجابتك'), findsOneWidget);
      expect(decorationOf(tester, 0).color, PlengoColors.green.soft);
      expect(decorationOf(tester, 1).color, PlengoColors.red.soft);
      final opacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).map((o) => o.opacity);
      expect(opacities, [1, 1, 0.6, 0.6]);
      expect(tester.getSemantics(find.byType(AnswerOption).at(0)).label, contains('الإجابة الصحيحة'));
      expect(tester.getSemantics(find.byType(AnswerOption).at(1)).label, contains('إجابتك، خاطئة'));
      semantics.dispose();
    });
  });

  group('FeedbackPanel', () {
    testWidgets('correct: «أحسنت!» and a green «متابعة»', (tester) async {
      var next = 0;
      await pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: FeedbackPanel(correct: true, onContinue: () => next++, explanation: const Text('شرح')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('أحسنت!'), findsOneWidget);
      expect(find.text('شرح'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      expect(next, 1);
    });

    testWidgets('wrong: the correct answer, the mistakes note, a red button and the report flag', (tester) async {
      var reports = 0;
      await pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: FeedbackPanel(
            correct: false,
            onContinue: () {},
            onReport: () => reports++,
            correctAnswer: const Text('6x'),
            note: FeedbackPanel.mistakesNote,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ليست الإجابة الصحيحة'), findsOneWidget);
      expect(find.text('الإجابة الصحيحة: '), findsOneWidget);
      expect(find.text(FeedbackPanel.mistakesNote), findsOneWidget);
      final button = tester.widget<PlengoButton>(find.widgetWithText(PlengoButton, 'فهمت، متابعة'));
      expect(button.variant, PlengoButtonVariant.danger);
      await tester.tap(find.byTooltip('إبلاغ عن مشكلة'));
      expect(reports, 1);
    });
  });

  group('progress', () {
    testWidgets('the bar always shows its label and reports its value', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const PlengoProgressBar(value: 0.35, label: 'السؤال 7 من 20'));
      await tester.pumpAndSettle();
      expect(find.text('السؤال 7 من 20'), findsOneWidget);
      expect(tester.getSemantics(find.byType(PlengoProgressBar)), isSemantics(label: 'السؤال 7 من 20', value: '35%'));
      expect(
        tester.getSize(find.descendant(of: find.byType(PlengoProgressBar), matching: find.byType(CustomPaint)).first),
        isA<Size>().having((s) => s.height, 'height', 10),
      );
      semantics.dispose();
    });

    testWidgets('the ring shows its centre value', (tester) async {
      await pump(tester, const ProgressRing(value: 0.6, label: '12/20', size: 76));
      expect(find.text('12/20'), findsOneWidget);
      expect(tester.getSize(find.byType(ProgressRing)), const Size(76, 76));
    });
  });

  group('selectors', () {
    testWidgets('PillSelector: tapping a pill selects it (ink fill, white bold text)', (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = 'bac';
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PillSelector<String>(
            options: const [
              PlengoOption('9', 'التاسع'),
              PlengoOption('bac', 'البكالوريا'),
              PlengoOption('uni', 'الجامعة'),
            ],
            selected: selected,
            onSelected: (v) => setState(() => selected = v),
          ),
        ),
      );
      Text label(String t) => tester.widget<Text>(find.text(t));
      expect(label('البكالوريا').style!.color, Colors.white);
      expect(label('الجامعة').style!.color, PlengoSurface.light.ink);
      await tester.tap(find.text('الجامعة'));
      await tester.pumpAndSettle();
      expect(selected, 'uni');
      expect(label('الجامعة').style!.color, Colors.white);
      expect(label('الجامعة').style!.fontWeight, FontWeight.w700);
      expect(tester.getSemantics(find.widgetWithText(PlengoPill, 'الجامعة')), isSemantics(isSelected: true));
      expect(tester.getSize(find.widgetWithText(PlengoPill, 'الجامعة')).height, greaterThanOrEqualTo(44));
      semantics.dispose();
    });

    testWidgets('PillSelector in dark mode: yellow fill with dark text', (tester) async {
      await pump(
        tester,
        PillSelector<int>(
          options: const [PlengoOption(0, 'الكل'), PlengoOption(1, 'الأسئلة')],
          selected: 0,
          onSelected: (_) {},
        ),
        brightness: Brightness.dark,
      );
      expect(tester.widget<Text>(find.text('الكل')).style!.color, PlengoColors.ink);
    });

    testWidgets('SegmentedControl and RadioRow report their choice', (tester) async {
      var seg = 0;
      var radio = false;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              SegmentedControl<int>(
                segments: const [PlengoOption(0, 'نشطة'), PlengoOption(1, 'متقنة')],
                selected: seg,
                onChanged: (v) => setState(() => seg = v),
              ),
              RadioRow(title: 'عادي', selected: radio, onTap: () => setState(() => radio = true)),
            ],
          ),
        ),
      );
      await tester.tap(find.text('متقنة'));
      await tester.tap(find.text('عادي'));
      await tester.pumpAndSettle();
      expect(seg, 1);
      expect(radio, isTrue);
      expect(tester.getSemantics(find.text('متقنة')), isSemantics(isSelected: true));
    });
  });

  group('navigation', () {
    const destinations = [
      PlengoNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'الرئيسية'),
      PlengoNavDestination(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'المواد'),
      PlengoNavDestination(icon: Icons.style_outlined, selectedIcon: Icons.style, label: 'المراجعة'),
    ];

    testWidgets('the active tab has the yellow pill, the filled icon and a bold label', (tester) async {
      final semantics = tester.ensureSemantics();
      var index = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: PlengoNavBar(
                  destinations: destinations,
                  selectedIndex: index,
                  onSelected: (i) => setState(() => index = i),
                ),
              ),
            ),
          ),
        ),
      );
      Color? pillOf(IconData icon) {
        final pill = tester.widget<AnimatedContainer>(
          find.ancestor(of: find.byIcon(icon), matching: find.byType(AnimatedContainer)).first,
        );
        return (pill.decoration! as BoxDecoration).color;
      }

      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(pillOf(Icons.menu_book), PlengoColors.yellow.base);
      expect(pillOf(Icons.home_outlined), Colors.transparent);
      expect(tester.widget<Text>(find.text('المواد')).style!.fontWeight, FontWeight.w700);
      expect(tester.getSemantics(find.text('المواد')), isSemantics(isSelected: true));

      await tester.tap(find.text('الرئيسية'));
      await tester.pumpAndSettle();
      expect(index, 0);
      expect(pillOf(Icons.home), PlengoColors.yellow.base);
      expect(tester.widget<Text>(find.text('المواد')).style!.fontWeight, FontWeight.w600);
      semantics.dispose();
    });

    testWidgets('the side rail is 240 wide with a yellow active row', (tester) async {
      await pump(
        tester,
        SizedBox(
          height: 600,
          child: PlengoSideRail(destinations: destinations, selectedIndex: 2, onSelected: (_) {}),
        ),
      );
      expect(tester.getSize(find.byType(PlengoSideRail)).width, 240);
      final row = tester.widget<Material>(
        find.ancestor(of: find.text('المراجعة'), matching: find.byType(Material)).first,
      );
      expect(row.color, PlengoColors.yellow.base);
    });

    testWidgets('back and close buttons are 48 × 48 and labelled', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const Row(children: [PlengoBackButton(), PlengoCloseButton()]));
      expect(tester.getSize(find.byType(PlengoIconButton).first), const Size(48, 48));
      expect(find.bySemanticsLabel('رجوع'), findsOneWidget);
      expect(find.bySemanticsLabel('خروج'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('sheets and states', () {
    testWidgets('a confirm sheet returns the chosen action', (tester) async {
      bool? result;
      await pump(
        tester,
        Builder(
          builder: (context) => PlengoButton(
            label: 'افتح',
            onPressed: () async => result = await showConfirmSheet(
              context,
              title: 'تقدّمك محفوظ',
              primaryLabel: 'واصل التدريب',
              secondaryLabel: 'خروج',
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      expect(find.text('تقدّمك محفوظ'), findsOneWidget);
      await tester.tap(find.text('خروج'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('واصل التدريب'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('error state retries; skeletons are announced as loading', (tester) async {
      final semantics = tester.ensureSemantics();
      var retries = 0;
      await pump(
        tester,
        Column(
          children: [
            PlengoErrorState(title: 'تعذّر التحميل', onRetry: () => retries++),
            const PlengoLoadingSkeleton(rows: 1, hero: false),
          ],
        ),
      );
      await tester.tap(find.text('إعادة المحاولة'));
      expect(retries, 1);
      expect(find.bySemanticsLabel('جارٍ التحميل…'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('catalog', () {
    for (final step in [0, 1, 2]) {
      testWidgets('renders every component at font step $step without overflow', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  textScaler: TextScaler.linear(AppearanceSettings.fontScales[step]),
                ),
                child: const WidgetCatalogScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('داكن'));
        await tester.pumpAndSettle();
        final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.byType(ConfettiDots), 300, scrollable: list, maxScrolls: 200);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ConfettiDots), findsOneWidget);
      });
    }
  });
}
