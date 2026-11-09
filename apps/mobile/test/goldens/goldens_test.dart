import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/app/theme.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/debug/widget_catalog_screen.dart';
import 'package:plengo/features/questions/question_view.dart';
import 'package:plengo/shared/ui/ui.dart';

import '../access_test.dart' as access show entitlement, physicsScope, trackScope;
import '../flashcards_test.dart' as fc show card, deck, t0;
import '../helpers.dart';
import '../home_test.dart' as home show banner, teacher;
import '../learning_test.dart' as learning show graded;

/// Phase 6 golden tests (CLAUDE_CODE_PROMPT §2): the shared components (catalog sections), Home,
/// Question (unanswered / correct / wrong), Flashcard review (front / back) and Results, light and
/// dark, at 390×844, with the bundled MontserratArabic font so the Arabic text really renders.
///
/// Regenerate after an intended visual change: `flutter test --update-goldens test/goldens`.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final arabic = FontLoader('MontserratArabic');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      arabic.addFont(rootBundle.load('assets/fonts/MontserratArabic-$weight.otf'));
    }
    await arabic.load();
    // Bundled by `uses-material-design: true`; without it every icon is a box.
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  const phone = Size(390, 844);
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder screen() => find.byWidgetPredicate((w) => w is MaterialApp).first;

  Future<void> setTheme(PumpedApp app, WidgetTester tester, bool dark) async {
    await app.container.read(appearanceProvider.notifier).setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    await tester.pumpAndSettle();
  }

  String mode(bool dark) => dark ? 'dark' : 'light';

  group('shared components (catalog)', () {
    const sections = {
      'الألوان': 'colors',
      'الأزرار': 'buttons',
      'البطاقات': 'cards',
      'الشارات': 'chips',
      'التقدّم': 'progress',
      'القوائم': 'lists',
      'الاختيار': 'selectors',
      'خيارات الإجابة': 'answers',
      'النوافذ السفلية': 'sheets',
      'التنقل': 'navigation',
      'الحالات': 'states',
      'زينة': 'decoration',
    };
    for (final dark in [false, true]) {
      testWidgets('catalog sections, ${mode(dark)}', (tester) async {
        usePhone(tester);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: const Directionality(textDirection: TextDirection.rtl, child: WidgetCatalogScreen()),
          ),
        );
        await tester.pumpAndSettle();
        if (dark) {
          await tester.tap(find.text('داكن'));
          await tester.pumpAndSettle();
        }
        for (final MapEntry(key: title, value: name) in sections.entries) {
          final header = find.widgetWithText(SectionHeader, title);
          final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
          await tester.scrollUntilVisible(header, 200, scrollable: list, maxScrolls: 200);
          await tester.pumpAndSettle();
          Scrollable.ensureVisible(tester.element(header));
          await tester.pumpAndSettle();
          await expectLater(screen(), matchesGoldenFile('catalog_${name}_${mode(dark)}.png'));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Home', () {
    for (final dark in [false, true]) {
      testWidgets('home, ${mode(dark)}', (tester) async {
        usePhone(tester);
        final app = await pumpApp(
          tester,
          signedInAs: testMe,
          clock: () => fc.t0,
          arrangeHome: (h) => when(() => h.home()).thenAnswer(
            (_) async => testHome(
              unread: 3,
              resume: const [
                ResumeItem(
                  subjectId: 'p',
                  subjectNameAr: 'الفيزياء',
                  teacherTrackId: null,
                  trackTitleAr: null,
                  unitId: 'u1',
                  unitNameAr: 'الحركة',
                  lessonId: 'l1',
                  lessonNameAr: 'السرعة',
                  activityType: ResumeItemActivityType.question,
                  itemId: null,
                  itemTitleAr: null,
                  attemptId: null,
                  lastActivityAt: '2026-09-27T09:00:00Z',
                ),
              ],
              countdown: const ExamCountdown(titleAr: 'امتحان الشهادة الثانوية', examDate: '2027-06-01', daysLeft: 87),
              banners: [home.banner('b1', 'عرض الصيف', BannerAction.none)],
              today: const Today(
                dueCards: 12,
                goal: 20,
                done: 8,
                goalMet: false,
                streak: 4,
                week: [true, true, false, true, true, true, false],
              ),
              myAccess: [
                access.entitlement('e1', access.physicsScope, MyEntitlementState.active),
                access.entitlement('e2', access.trackScope, MyEntitlementState.active),
              ],
              freeSubjects: const [FreeSubject(subjectId: 'c', nameAr: 'الكيمياء', freeCount: 14, coverUrl: null)],
              followedTeachers: const [home.teacher],
              activeMistakes: 6,
            ),
          ),
        );
        await setTheme(app, tester, dark);
        await expectLater(screen(), matchesGoldenFile('home_${mode(dark)}.png'));
      });
    }
  });

  group('Question', () {
    StudentQuestion mcq(String id) => StudentQuestion(
      id: id,
      type: StudentQuestionType.mcq,
      subjectId: 'p',
      teacherTrackId: null,
      unitId: null,
      lessonId: null,
      sortOrder: 0,
      difficulty: null,
      isFree: true,
      locked: false,
      questionText: 'إذا كان f(x) = x^2 + 3x فما قيمة f\'(2)؟',
      options: [
        StudentOption(id: '$id-a', text: '7'),
        StudentOption(id: '$id-b', text: '10'),
        StudentOption(id: '$id-c', text: '4'),
        StudentOption(id: '$id-d', text: '2x + 3'),
      ],
    );

    Future<PumpedApp> openPractice(WidgetTester tester, bool dark) async {
      usePhone(tester);
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeCatalog: (c) => when(() => c.outline('p')).thenAnswer(
          (_) async => SubjectOutline(
            subject: subject('p', 'الرياضيات'),
            units: const [],
            lessons: const [],
            tracks: const [],
            access: noAccess,
            questionCount: const ContentCount(total: 10, free: 10),
            deckCount: noQuestions,
            quizCount: noQuestions,
          ),
        ),
        arrangeQuestions: (q) {
          final items = [for (var i = 0; i < 10; i++) mcq('q$i')];
          when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
            (_) async => StudentQuestionPage(items: items, nextCursor: null, totalCount: 10, accessibleCount: 10),
          );
          when(() => q.check(any(), selectedOptionId: any(named: 'selectedOptionId'))).thenAnswer((i) async {
            final id = i.positionalArguments.first as String;
            final picked = i.namedArguments[#selectedOptionId] as String?;
            return CheckResult(
              isCorrect: picked == '$id-a',
              correctOptionId: '$id-a',
              correctAnswer: null,
              explanation: 'المشتقة f\'(x) = 2x + 3، إذن f\'(2) = 7.',
            );
          });
        },
      );
      await setTheme(app, tester, dark);
      app.container.read(routerProvider).go('/subjects/p/questions');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التدريب'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);
      return app;
    }

    Future<void> answer(WidgetTester tester, int option) async {
      await tester.tap(find.byType(AnswerOption).at(option));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحقق'));
      await tester.pumpAndSettle();
    }

    for (final dark in [false, true]) {
      testWidgets('unanswered, ${mode(dark)}', (tester) async {
        await openPractice(tester, dark);
        await expectLater(screen(), matchesGoldenFile('question_unanswered_${mode(dark)}.png'));
      });

      testWidgets('correct, ${mode(dark)}', (tester) async {
        await openPractice(tester, dark);
        await answer(tester, 0);
        expect(find.byType(AnswerFeedbackPanel), findsOneWidget);
        await expectLater(screen(), matchesGoldenFile('question_correct_${mode(dark)}.png'));
      });

      testWidgets('wrong, ${mode(dark)}', (tester) async {
        await openPractice(tester, dark);
        await answer(tester, 1);
        expect(find.byType(AnswerFeedbackPanel), findsOneWidget);
        await expectLater(screen(), matchesGoldenFile('question_wrong_${mode(dark)}.png'));
      });
    }
  });

  group('Flashcard review', () {
    for (final dark in [false, true]) {
      testWidgets('front and back, ${mode(dark)}', (tester) async {
        usePhone(tester);
        final app = await pumpApp(
          tester,
          signedInAs: testMe,
          clock: () => fc.t0,
          arrangeFlashcards: (f) {
            when(() => f.deck('d1')).thenAnswer((_) async => fc.deck());
            when(() => f.deckCards('d1')).thenAnswer(
              (_) async =>
                  DeckCards(deck: fc.deck(), cards: [for (var i = 0; i < 3; i++) fc.card(i)], urlsExpireAt: ''),
            );
          },
        );
        await setTheme(app, tester, dark);
        app.container.read(routerProvider).go('/decks/d1/study');
        await tester.pumpAndSettle();
        await expectLater(screen(), matchesGoldenFile('flashcard_front_${mode(dark)}.png'));
        await tester.tap(find.text('اقلب البطاقة'));
        await tester.pumpAndSettle();
        await expectLater(screen(), matchesGoldenFile('flashcard_back_${mode(dark)}.png'));
        // Let the debounced background sync run so no timer outlives the test.
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });

  group('Results', () {
    for (final dark in [false, true]) {
      testWidgets('results, ${mode(dark)}', (tester) async {
        usePhone(tester);
        final app = await pumpApp(
          tester,
          signedInAs: testMe,
          arrangeLearning: (l) => when(() => l.attempt('a1')).thenAnswer((_) async => learning.graded()),
        );
        await setTheme(app, tester, dark);
        app.container.read(routerProvider).go('${Routes.attempts}/a1/results');
        await tester.pumpAndSettle();
        expect(find.text('متابعة'), findsOneWidget);
        await expectLater(screen(), matchesGoldenFile('results_${mode(dark)}.png'));
      });
    }
  });
}
