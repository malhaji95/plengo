import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/generated/export.dart';

import 'flashcards_test.dart' as fc show card, deck, deckWith, reviewState, t0;
import 'helpers.dart';
import 'home_test.dart' as home show notification;
import 'learning_test.dart' as learning show attempt, graded, question, quiz, summary;
import 'questions_test.dart' as questions show mcq, written, locked;
import 'teachers_test.dart' as teachers show profile, teacher;

/// Phase 6 QA (CLAUDE_CODE_PROMPT §2): every redesigned screen at 360×800 and 1024×768, light and
/// dark, font steps 0 and 2, lays out without overflow or exceptions, and its tap targets are at
/// least 48 dp with labels on the buttons.
void main() {
  setUpAll(() {
    registerFallbackValue(MistakeFilterStatus.active);
    registerFallbackValue(AttemptStatus.submitted);
  });

  const sizes = [Size(360, 800), Size(1024, 768)];

  const longName = 'الفيزياء والكيمياء للصف الثالث الثانوي العلمي';
  SubjectOutline physics() => SubjectOutline(
    subject: subject('p', longName, description: 'الميكانيك والكهرباء والضوء والفيزياء الحديثة'),
    units: const [
      UnitWithLessons(
        id: 'u1',
        subjectId: 'p',
        code: 'u1',
        titleAr: 'الوحدة الأولى: الميكانيك والحركة في بعدين',
        sortOrder: 0,
        lessons: [
          Lesson(id: 'l1', subjectId: 'p', unitId: 'u1', code: 'l1', titleAr: 'السرعة المتوسطة واللحظية', sortOrder: 0),
          Lesson(id: 'l2', subjectId: 'p', unitId: 'u1', code: 'l2', titleAr: 'التسارع وقوانين نيوتن', sortOrder: 1),
        ],
      ),
      UnitWithLessons(
        id: 'u2',
        subjectId: 'p',
        code: 'u2',
        titleAr: 'الوحدة الثانية: الكهرباء',
        sortOrder: 1,
        lessons: [Lesson(id: 'l3', subjectId: 'p', unitId: 'u2', code: 'l3', titleAr: 'قانون أوم', sortOrder: 0)],
      ),
    ],
    lessons: const [],
    tracks: const [
      SubjectTrack(
        id: 'tr1',
        teacherId: 't1',
        teacherNameAr: 'أ. أحمد',
        teacherPhotoUrl: null,
        titleAr: 'أ. أحمد — فيزياء بكالوريا',
        description: 'شرح كامل للمنهاج مع حل نماذج الامتحانات',
        coverUrl: null,
        hasAccess: false,
      ),
    ],
    access: noAccess,
    questionCount: const ContentCount(total: 480, free: 40),
    deckCount: const ContentCount(total: 12, free: 2),
    quizCount: const ContentCount(total: 12, free: 1),
  );

  DueCard due(int i) => DueCard(
    card: fc.card(i),
    deckTitleAr: 'مجموعة قوانين نيوتن',
    subjectId: 'p',
    subjectNameAr: longName,
    state: fc.reviewState('c$i'),
  );

  const acc = Accuracy(answered: 1240, correct: 967, accuracyPercent: 78);

  Future<PumpedApp> open(WidgetTester tester, String location) async {
    tester.view.physicalSize = sizes.first;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      clock: () => fc.t0,
      arrangeCatalog: (c) {
        when(() => c.subjects(any())).thenAnswer((_) async => [catalogSubject('p', longName, hasAccess: true)]);
        when(() => c.outline('p')).thenAnswer((_) async => physics());
      },
      arrangeTeachers: (t) {
        when(() => t.teachers()).thenAnswer((_) async => [teachers.teacher(following: true, followers: 1200)]);
        when(() => t.profile('t1')).thenAnswer((_) async => teachers.profile(following: true, followers: 1200));
        when(() => t.track('tr1')).thenAnswer(
          (_) async => TrackDetail(
            track: teachers.profile().tracks.first,
            teacher: teachers.teacher(),
            subject: subject('p', longName),
            access: noAccess,
            questionCount: const ContentCount(total: 30, free: 5),
            deckCount: const ContentCount(total: 3, free: 1),
            quizCount: const ContentCount(total: 2, free: 0),
          ),
        );
      },
      arrangeQuestions: (q) => when(() => q.page(any(), cursor: any(named: 'cursor'))).thenAnswer(
        (_) async => StudentQuestionPage(
          items: [questions.mcq, questions.written, questions.locked],
          nextCursor: null,
          totalCount: 3,
          accessibleCount: 2,
        ),
      ),
      arrangeFlashcards: (f) {
        when(() => f.decks(any())).thenAnswer(
          (_) async => [fc.deckWith('d1', cardCount: 42, isFree: true), fc.deckWith('d3', cardCount: 11, locked: true)],
        );
        when(() => f.deck('d1')).thenAnswer((_) async => fc.deck());
        when(
          () => f.deckCards('d1'),
        ).thenAnswer((_) async => DeckCards(deck: fc.deck(), cards: [fc.card(0), fc.card(1)], urlsExpireAt: ''));
        when(
          () => f.due(subjectId: any(named: 'subjectId')),
        ).thenAnswer((_) async => DueCards(cards: [due(0), due(1)], userCards: const [], urlsExpireAt: ''));
      },
      arrangeLearning: (l) {
        when(() => l.quizzes(any())).thenAnswer((_) async => [learning.quiz()]);
        when(() => l.attempt('a1')).thenAnswer((_) async => learning.attempt());
        when(() => l.attempt('a2')).thenAnswer(
          (_) async => Attempt(
            attempt: learning.summary(id: 'a2', mode: AttemptSummaryMode.practice),
            questions: [learning.question('q1'), learning.question('q2')],
            serverTime: '2026-09-27T09:00:00.000Z',
          ),
        );
        when(() => l.attempt('a3')).thenAnswer((_) async => learning.graded());
        when(() => l.quiz('q1')).thenAnswer((_) async => learning.quiz(total: 30, accessible: 10));
        when(
          () => l.attempts(
            quizId: any(named: 'quizId'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => const AttemptSummaryPage(items: [], nextCursor: null));
        when(() => l.mistakes(status: any(named: 'status'))).thenAnswer(
          (_) async => const MistakeList(
            items: [
              Mistake(
                questionId: 'm1',
                type: MistakeType.trueFalse,
                questionText: 'إذا كان f(x) = x^2 + 3x فإن f\'(2) = 7، صح أم خطأ؟',
                subjectId: 'p',
                subjectNameAr: longName,
                teacherTrackId: null,
                trackTitleAr: null,
                unitId: 'u1',
                unitNameAr: 'الوحدة الأولى: الميكانيك والحركة في بعدين',
                lessonId: null,
                lessonNameAr: null,
                status: MistakeStatus.active,
                wrongCount: 12,
                correctStreak: 2,
                firstWrongAt: '2026-09-20T00:00:00Z',
                lastWrongAt: '2026-09-21T00:00:00Z',
              ),
            ],
            activeCount: 23,
            masteredCount: 140,
            masteryStreak: 3,
            nextCursor: null,
          ),
        );
        when(() => l.overview()).thenAnswer(
          (_) async => const StatsOverview(
            totals: acc,
            quizzesCompleted: 14,
            studyDays: 32,
            currentStreak: 5,
            averageTimeMs: 42000,
            mistakes: Mistakes(active: 23, mastered: 140),
            subjects: [
              SubjectAccuracy(
                answered: 1240,
                correct: 967,
                accuracyPercent: 78,
                subjectId: 'p',
                subjectNameAr: longName,
                teacherTrackId: null,
                trackTitleAr: null,
              ),
            ],
            byType: [TypeAccuracy(answered: 10, correct: 5, accuracyPercent: 50, type: TypeAccuracyType.written)],
            weakestUnits: [
              UnitAccuracy(
                answered: 20,
                correct: 11,
                accuracyPercent: 54,
                unitId: 'u1',
                unitNameAr: 'الوحدة الثانية: النهايات والاستمرار',
                subjectId: 'p',
                subjectNameAr: longName,
              ),
            ],
            mostMissed: [
              MissedQuestion(
                questionId: 'q',
                questionText: 'سؤال طويل جداً عن الدوال f(x) = (x + 1)^2',
                subjectNameAr: longName,
                wrongCount: 9,
              ),
            ],
          ),
        );
        when(() => l.trend()).thenAnswer(
          (_) async => StatsTrend(
            weeks: [
              for (var i = 0; i < 12; i++)
                TrendWeek(answered: 4, correct: 3, accuracyPercent: 55 + 2 * i, weekStart: '2026-07-01'),
            ],
          ),
        );
        when(() => l.flashcardStats()).thenAnswer(
          (_) async => FlashcardStats(
            dueToday: 12,
            forecast: [for (var i = 0; i < 7; i++) DayCount(date: '2026-09-27', count: 12 - i)],
            reviewsPerDay: [for (var i = 0; i < 30; i++) const DayCount(date: '2026-09-01', count: 4)],
            retentionPercent: 90,
            byState: const ByState(newValue: 100, learning: 20, review: 300, relearning: 4),
          ),
        );
        when(() => l.bookmarks()).thenAnswer(
          (_) async => const BookmarkList(
            items: [
              Bookmark(
                id: 'b1',
                itemType: BookmarkItemType.question,
                itemId: 'q9',
                createdAt: '2026-09-20T00:00:00Z',
                locked: true,
                available: true,
                titleAr: null,
                subjectId: 'p',
                subjectNameAr: longName,
                question: null,
                deck: null,
                card: null,
                userCard: null,
              ),
              Bookmark(
                id: 'b2',
                itemType: BookmarkItemType.deck,
                itemId: 'd1',
                createdAt: '2026-09-20T00:00:00Z',
                locked: false,
                available: true,
                titleAr: 'قوانين نيوتن',
                subjectId: 'p',
                subjectNameAr: longName,
                question: null,
                deck: null,
                card: null,
                userCard: null,
              ),
            ],
            nextCursor: null,
            urlsExpireAt: '',
          ),
        );
      },
      arrangeHome: (h) {
        when(() => h.notifications(cursor: any(named: 'cursor'))).thenAnswer(
          (_) async => NotificationPage(
            items: [
              home.notification('n1', 'محتوى جديد في $longName', type: NotificationType.newContent),
              home.notification('n2', 'لديك 12 بطاقة للمراجعة اليوم', type: NotificationType.dueReminder, read: true),
              home.notification('n3', 'عرض خاص لطلاب البكالوريا', type: NotificationType.promotion),
            ],
            nextCursor: null,
            unreadCount: 2,
          ),
        );
        when(() => h.markRead(any())).thenAnswer((_) async => 1);
        when(() => h.markAllRead()).thenAnswer((_) async => 0);
        when(() => h.goal()).thenAnswer((_) async => 20);
        when(() => h.preferences()).thenAnswer(
          (_) async => const NotificationPreferences(
            learning: true,
            promotions: false,
            reminderTime: '19:00',
            reviewReminder: true,
          ),
        );
      },
    );
    app.container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return app;
  }

  /// Lays the open screen out in every QA configuration and fails on the first exception.
  Future<void> sweep(WidgetTester tester, PumpedApp app, String label, Finder visible) async {
    final appearance = app.container.read(appearanceProvider.notifier);
    for (final size in sizes) {
      for (final dark in [false, true]) {
        for (final step in [0, 2]) {
          final config = '$label @ ${size.width.toInt()}×${size.height.toInt()} ${dark ? 'dark' : 'light'} step $step';
          tester.view.physicalSize = size;
          await appearance.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
          await appearance.setFontStep(step);
          await tester.pumpAndSettle();
          final error = tester.takeException();
          expect(error, isNull, reason: '$config: $error');
          expect(visible, findsWidgets, reason: config);
        }
      }
    }
    // Back to phone, light, normal text for the guideline checks.
    tester.view.physicalSize = sizes.first;
    await appearance.setThemeMode(ThemeMode.light);
    await appearance.setFontStep(1);
    await tester.pumpAndSettle();
  }

  Future<void> checkTargets(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  }

  final screens = <(String, String, Finder Function())>[
    ('subject page (learning path)', '/subjects/p', () => find.text('السرعة المتوسطة واللحظية')),
    ('lesson', '/subjects/p/lessons/l1', () => find.text('السرعة المتوسطة واللحظية')),
    ('quiz page', '/quizzes/q1', () => find.text('اختبار الحركة')),
    ('subject quizzes', '/subjects/p/quizzes', () => find.text('اختبار الحركة')),
    ('questions list', '/subjects/p/questions', () => find.text('ابدأ التدريب')),
    ('teachers', Routes.teachers, () => find.text('أ. أحمد')),
    ('teacher profile', '${Routes.teachers}/t1', () => find.text('أ. أحمد — فيزياء بكالوريا')),
    ('track page', '${Routes.tracks}/tr1', () => find.text('أسئلة المسار')),
    ('notifications', Routes.notifications, () => find.text('عرض خاص لطلاب البكالوريا')),
    ('account', Routes.account, () => find.text('الإشعارات والهدف اليومي')),
    ('redeem', '${Routes.redeem}?subjectId=p', () => find.text('هذا المحتوى يحتاج إلى تفعيل')),
    ('review tab', Routes.review, () => find.byType(Scaffold)),
    ('mistakes', Routes.mistakes, () => find.text('اختبر أخطائي')),
    ('stats', Routes.stats, () => find.byType(Scaffold)),
    ('saved', Routes.saved, () => find.text('قوانين نيوتن')),
    ('subject decks', '/subjects/p/decks', () => find.text('مجموعة d1')),
    ('deck page', '/decks/d1', () => find.text('قوانين نيوتن')),
    ('browse', '/decks/d1/browse', () => find.byType(Scaffold)),
    ('study', '/decks/d1/study', () => find.text('اقلب البطاقة')),
    ('subjects tab', Routes.subjects, () => find.text(longName)),
    ('home', Routes.home, () => find.byType(Scaffold)),
    ('notification settings', Routes.notificationSettings, () => find.text('تذكير المراجعة')),
    ('my access', Routes.myAccess, () => find.byType(Scaffold)),
    ('exam', '${Routes.attempts}/a1', () => find.text('إنهاء الامتحان')),
    ('practice attempt', '${Routes.attempts}/a2', () => find.byTooltip('خروج')),
    ('results', '${Routes.attempts}/a3/results', () => find.text('متابعة')),
  ];

  for (final (label, location, visible) in screens) {
    testWidgets('$label: no overflow at 360/1024, light/dark, font steps 0 and 2; 48 dp labelled targets', (
      tester,
    ) async {
      final app = await open(tester, location);
      expect(tester.takeException(), isNull);
      await sweep(tester, app, label, visible());
      await checkTargets(tester);
      // Let the debounced background syncs run so no timer outlives the test.
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('study: the back of a card fits in every configuration', (tester) async {
    final app = await open(tester, '/decks/d1/study');
    await tester.tap(find.text('اقلب البطاقة'));
    await tester.pumpAndSettle();
    await sweep(tester, app, 'study (back)', find.text('جيد'));
    await checkTargets(tester);
    await tester.pump(const Duration(seconds: 3));
  });
}
