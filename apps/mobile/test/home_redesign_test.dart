import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/redesign_flags.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/features/home/notification_screens.dart';
import 'package:plengo/features/home/streak_screen.dart';
import 'package:plengo/shared/ui/ui.dart';

import 'access_test.dart' show entitlement, physicsScope, trackScope;
import 'helpers.dart';
import 'home_test.dart' show banner, location, teacher;

/// Redesign v2: Home (V-Home and its states), the goal step (V-Goal), the streak moment (V-Streak) and
/// the review-reminder switch in the notification settings.
void main() {
  void useSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  ScopeProgress progress(
    String subjectId, {
    String? teacherTrackId,
    int percent = 0,
    List<UnitProgress> units = const [],
    List<LessonProgress> lessons = const [],
  }) => ScopeProgress(
    questionsAttempted: 0,
    questionsCorrect: 0,
    questionsTotal: 0,
    quizzesCompleted: 0,
    quizzesTotal: 0,
    flashcardsStudied: 0,
    flashcardsTotal: 0,
    completionPercent: percent,
    subjectId: subjectId,
    teacherTrackId: teacherTrackId,
    lastActivityAt: null,
    units: units,
    lessons: lessons,
  );

  UnitProgress unit(String id, int percent) => UnitProgress(
    questionsAttempted: 0,
    questionsCorrect: 0,
    questionsTotal: 0,
    quizzesCompleted: 0,
    quizzesTotal: 0,
    flashcardsStudied: 0,
    flashcardsTotal: 0,
    completionPercent: percent,
    unitId: id,
  );

  LessonProgress lesson(String id, int percent) => LessonProgress(
    questionsAttempted: 0,
    questionsCorrect: 0,
    questionsTotal: 0,
    quizzesCompleted: 0,
    quizzesTotal: 0,
    flashcardsStudied: 0,
    flashcardsTotal: 0,
    completionPercent: percent,
    lessonId: id,
  );

  const resumeLesson = ResumeItem(
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
  );

  Home fullHome({int mistakes = 6, List<ResumeItem> resume = const [resumeLesson]}) => testHome(
    unread: 3,
    resume: resume,
    countdown: const ExamCountdown(titleAr: 'امتحان الشهادة الثانوية', examDate: '2027-06-01', daysLeft: 87),
    banners: [banner('b1', 'عرض الصيف', BannerAction.none), banner('b2', 'جديد', BannerAction.none)],
    today: const Today(dueCards: 12, goal: 20, done: 8, goalMet: false, streak: 4, week: noWeek),
    myAccess: [
      entitlement('e1', physicsScope, MyEntitlementState.active),
      entitlement('e2', trackScope, MyEntitlementState.active),
    ],
    freeSubjects: const [FreeSubject(subjectId: 'c', nameAr: 'الكيمياء', freeCount: 14, coverUrl: null)],
    followedTeachers: const [teacher],
    activeMistakes: mistakes,
  );

  group('Home', () {
    testWidgets('order follows homeOrderV2; the mistakes row shows only with mistakes', (tester) async {
      useSize(tester, const Size(390, 2400));
      await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome()),
      );
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      final hero = top('الحركة'); // no item title: the unit's name
      final today = top('هدف اليوم: 8 من 20');
      final countdown = top('باقي 87 يوماً على امتحان الشهادة الثانوية');
      final banners = top('banner:عرض الصيف');
      final mine = top('موادّي ومساراتي');
      final free = top('محتوى مجاني');
      final teachers = top('مدرسون أتابعهم');
      if (RedesignFlags.homeOrderV2) {
        expect(find.text('تابع من حيث توقفت'), findsOneWidget);
        final order = [hero, today, countdown, banners, mine, free, teachers];
        for (var i = 1; i < order.length; i++) {
          expect(order[i - 1], lessThan(order[i]), reason: 'section $i is out of order');
        }
        // The mistakes row sits inside the Today card, before the countdown.
        expect(top('6 أسئلة في بنك الأخطاء'), inExclusiveRange(today, countdown));
      } else {
        expect(countdown, lessThan(banners));
        expect(banners, lessThan(today));
        expect(today, lessThan(hero));
        expect(hero, lessThan(mine));
      }
    });

    testWidgets('no mistakes: no mistakes row', (tester) async {
      useSize(tester, const Size(390, 2400));
      await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome(mistakes: 0)),
      );
      expect(find.textContaining('في بنك الأخطاء'), findsNothing);
      expect(find.text('مراجعة الأخطاء'), findsNothing);
    });

    testWidgets('Continue shows the lesson progress and resumes; cards show rings and unit progress', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome()),
        arrangeLearning: (l) {
          when(() => l.progress('p', teacherTrackId: null)).thenAnswer(
            (_) async => progress(
              'p',
              percent: 42,
              units: [unit('u1', 100), unit('u2', 30), unit('u3', 0)],
              lessons: [lesson('l1', 35)],
            ),
          );
          when(
            () => l.progress('p', teacherTrackId: 'tr1'),
          ).thenAnswer((_) async => progress('p', teacherTrackId: 'tr1', percent: 60));
        },
      );
      // DECISIONS #5: the lesson's completion first.
      expect(find.text('\u206635%\u2069 مكتمل'), findsOneWidget);
      expect(find.text('أسئلة · الفيزياء · السرعة'), findsOneWidget);
      // DECISIONS #6: one ring per scope, and the unit caption for subjects.
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('الوحدة 2 من 3'), findsOneWidget);
      expect(find.text('أ. أحمد · الفيزياء'), findsOneWidget);
      // One call per scope even though the subject appears in the hero and in the cards.
      verify(() => app.learning.progress('p', teacherTrackId: null)).called(1);

      await tester.tap(find.text('تابع'));
      await tester.pump();
      expect(location(app), '/subjects/p/questions?lessonId=l1');
    });

    testWidgets('free content uses the subject colour without a cover and opens the subject', (tester) async {
      useSize(tester, const Size(390, 2400));
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome()),
      );
      expect(find.text('مجاني'), findsOneWidget);
      await tester.tap(find.text('الكيمياء'));
      await tester.pump();
      expect(location(app), '/subjects/c');
    });

    testWidgets('the bell shows the unread count and opens the inbox', (tester) async {
      await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) {
          when(() => h.home()).thenAnswer((_) async => fullHome());
          when(
            () => h.notifications(),
          ).thenAnswer((_) async => const NotificationPage(items: [], nextCursor: null, unreadCount: 0));
        },
      );
      expect(find.bySemanticsLabel('الإشعارات، 3'), findsOneWidget);
      await tester.tap(find.byTooltip('الإشعارات'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('لا توجد إشعارات'), findsOneWidget);
      expect(find.text('إعدادات الإشعارات'), findsOneWidget);
    });

    testWidgets('wide screens put Continue and Today side by side', (tester) async {
      useSize(tester, const Size(1280, 1400));
      await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome()),
      );
      final hero = tester.getRect(find.byType(PlengoHeroCard));
      final today = tester.getRect(find.text('اليوم'));
      if (RedesignFlags.homeOrderV2) {
        expect(today.top, lessThan(hero.bottom));
        expect(today.left, lessThan(hero.left)); // RTL: Today is at the end (left)
      } else {
        expect(today.top, lessThan(hero.top));
      }
    });

    testWidgets('loading shows a skeleton announced once', (tester) async {
      final never = Completer<Home>();
      await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) => when(() => h.home()).thenAnswer((_) => never.future),
      );
      expect(find.byType(SkeletonGroup), findsOneWidget);
      expect(find.bySemanticsLabel(SkeletonGroup.loadingLabel), findsOneWidget);
    });

    testWidgets('offline: dark banner with its links', (tester) async {
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        offlinePacks: true,
        arrangeHome: (h) => when(() => h.home()).thenThrow(const ApiException('NETWORK_ERROR', 'لا يوجد اتصال')),
      );
      expect(find.text('أنت غير متصل بالإنترنت'), findsOneWidget);
      expect(find.text('تحديث'), findsOneWidget);
      await tester.tap(find.text('المراجعة').first);
      await tester.pumpAndSettle();
      expect(location(app), Routes.review);
    });

    for (final dark in [false, true]) {
      testWidgets('360×800, large text, ${dark ? 'dark' : 'light'}: no overflow', (tester) async {
        useSize(tester, const Size(360, 800));
        final app = await pumpApp(
          tester,
          signedInAs: testMe,
          arrangeHome: (h) => when(() => h.home()).thenAnswer((_) async => fullHome()),
        );
        await app.container.read(appearanceProvider.notifier).setFontStep(2);
        await app.container.read(appearanceProvider.notifier).setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
        await tester.pumpAndSettle();
        for (var i = 0; i < 8; i++) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        expect(find.text('مدرسون أتابعهم'), findsOneWidget);
      });
    }
  });

  group('goal step (V-Goal)', () {
    Future<({PumpedApp app, List<bool> saved})> openGoal(WidgetTester tester, {int fontStep = 1}) async {
      final saved = <bool>[];
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) {
          when(() => h.setGoal(any())).thenAnswer((i) async => i.positionalArguments.first as int);
          when(() => h.setPreferences(reviewReminder: any(named: 'reviewReminder'))).thenAnswer((i) async {
            final on = i.namedArguments[#reviewReminder] as bool;
            saved.add(on);
            return NotificationPreferences(
              learning: true,
              promotions: false,
              reminderTime: '19:00',
              reviewReminder: on,
            );
          });
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
      await app.container.read(appearanceProvider.notifier).setFontStep(fontStep);
      app.container.read(routerProvider).go(Routes.onboardingGoal);
      await tester.pumpAndSettle();
      return (app: app, saved: saved);
    }

    testWidgets('lists the goals, saves the goal and the reminder, then goes home', (tester) async {
      useSize(tester, const Size(390, 1200));
      final (:app, :saved) = await openGoal(tester);
      expect(find.text('ما هدفك اليومي؟'), findsOneWidget);
      for (final label in ['خفيف', 'عادي', 'جاد', 'مكثّف', 'تحدٍّ']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('30 عنصراً يومياً'), findsOneWidget);
      expect(find.text('حوالي 15 دقيقة'), findsOneWidget);
      expect(find.text('حوالي 10 دقائق'), findsOneWidget);
      expect(find.text('\u206619:00\u2069 بتوقيت دمشق'), findsOneWidget);
      // The reminder is on by default.
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

      await tester.tap(find.text('جاد'));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      verify(() => app.home.setGoal(30)).called(1);
      expect(saved, [false]);
      expect(location(app), Routes.home);
    });

    testWidgets('«تخطي» goes home without saving', (tester) async {
      final (:app, :saved) = await openGoal(tester);
      await tester.tap(find.text('تخطي'));
      await tester.pumpAndSettle();
      verifyNever(() => app.home.setGoal(any()));
      expect(saved, isEmpty);
      expect(location(app), Routes.home);
    });

    testWidgets('a failed save stays on the step and says why', (tester) async {
      final (:app, :saved) = await openGoal(tester);
      when(() => app.home.setGoal(any())).thenThrow(const ApiException('NETWORK_ERROR', 'لا يوجد اتصال'));
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد اتصال'), findsOneWidget);
      expect(location(app), Routes.onboardingGoal);
    });

    testWidgets('large text at 360×800 does not overflow', (tester) async {
      useSize(tester, const Size(360, 800));
      await openGoal(tester, fontStep: 2);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ذكّرني بالمراجعة'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
    });
  });

  group('streak moment (V-Streak)', () {
    // Thursday 2026-11-12, 15:00 in Damascus.
    final thursday = DateTime.utc(2026, 11, 12, 12).millisecondsSinceEpoch;
    const week = [false, true, true, true, true, true, true];

    Future<PumpedApp> openStreak(WidgetTester tester, {bool push = true, int streak = 6}) async {
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        clock: () => thursday,
        arrangeHome: (h) => when(() => h.home()).thenAnswer(
          (_) async => testHome(
            today: Today(dueCards: 0, goal: 20, done: 20, goalMet: true, streak: streak, week: week),
          ),
        ),
      );
      final router = app.container.read(routerProvider);
      if (push) {
        unawaited(router.push(Routes.streak));
      } else {
        router.go(Routes.streak);
      }
      await tester.pumpAndSettle();
      return app;
    }

    test('weekday of a business day and encouraging copy', () {
      expect(StreakScreen.weekdayOf(0), 4); // Thursday 1970-01-01
      expect(StreakScreen.encouragement(6, 'سارة'), 'أحسنت يا سارة. حقّق هدفك غداً لتصل إلى أسبوع كامل.');
      expect(StreakScreen.encouragement(1, null), 'أحسنت. حقّق هدفك غداً لتصل إلى يومين متتاليين.');
      expect(StreakScreen.encouragement(3, ''), 'أحسنت. حقّق هدفك غداً لتصل إلى 4 أيام متتالية.');
      expect(StreakScreen.encouragement(30, 'سارة'), 'أحسنت يا سارة! استمر على هذا الإيقاع.');
      expect(StreakScreen.encouragement(0, 'سارة'), contains('بداية جديدة'));
    });

    testWidgets('shows the streak, the copy and the week; «متابعة» goes back', (tester) async {
      final app = await openStreak(tester);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('أيام متتالية حققت فيها هدفك'), findsOneWidget);
      expect(find.text('أحسنت يا سارة. حقّق هدفك غداً لتصل إلى أسبوع كامل.'), findsOneWidget);
      // Six days with ✓ (never colour alone), the oldest first and today (Thursday) last.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(6));
      expect(find.bySemanticsLabel('حققت هدفك في 6 من آخر 7 أيام'), findsOneWidget);
      expect(find.bySemanticsLabel('الخميس، اليوم: مكتمل'), findsOneWidget);
      expect(find.bySemanticsLabel('الجمعة: لم يكتمل'), findsOneWidget);

      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(location(app), Routes.home);
      expect(find.byType(StreakScreen), findsNothing);
    });

    testWidgets('with nothing to go back to, «متابعة» goes home', (tester) async {
      final app = await openStreak(tester, push: false);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(location(app), Routes.home);
    });

    testWidgets('large text at 360×800 in dark mode does not overflow', (tester) async {
      useSize(tester, const Size(360, 800));
      final app = await openStreak(tester);
      await app.container.read(appearanceProvider.notifier).setFontStep(2);
      await app.container.read(appearanceProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('notification settings: review reminder', () {
    Future<({PumpedApp app, List<bool> saved})> openSettings(
      WidgetTester tester, {
      bool learning = true,
      bool reviewReminder = true,
    }) async {
      final saved = <bool>[];
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrangeHome: (h) {
          when(() => h.preferences()).thenAnswer(
            (_) async => NotificationPreferences(
              learning: learning,
              promotions: false,
              reminderTime: '18:00',
              reviewReminder: reviewReminder,
            ),
          );
          when(() => h.goal()).thenAnswer((_) async => 20);
          when(() => h.setPreferences(reviewReminder: any(named: 'reviewReminder'))).thenAnswer((i) async {
            final on = i.namedArguments[#reviewReminder] as bool;
            saved.add(on);
            return NotificationPreferences(
              learning: true,
              promotions: false,
              reminderTime: '19:00',
              reviewReminder: on,
            );
          });
        },
      );
      app.container.read(routerProvider).go('${Routes.account}/notifications');
      await tester.pumpAndSettle();
      return (app: app, saved: saved);
    }

    Finder reminderSwitch() => find.widgetWithText(SwitchListTile, 'تذكير المراجعة');
    DropdownButton<String> timeDropdown(WidgetTester tester) =>
        tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));

    testWidgets('the switch saves the preference', (tester) async {
      final (:app, :saved) = await openSettings(tester);
      expect(tester.widget<SwitchListTile>(reminderSwitch()).value, isTrue);
      expect(timeDropdown(tester).onChanged, isNotNull);
      await tester.tap(reminderSwitch());
      await tester.pumpAndSettle();
      expect(saved, [false]);
      verify(() => app.home.preferences()).called(2); // reloaded after saving
    });

    testWidgets('reminder off: the time cannot be changed', (tester) async {
      await openSettings(tester, reviewReminder: false);
      expect(tester.widget<SwitchListTile>(reminderSwitch()).value, isFalse);
      expect(timeDropdown(tester).onChanged, isNull);
    });

    testWidgets('learning off: the reminder and its time are disabled', (tester) async {
      await openSettings(tester, learning: false);
      expect(tester.widget<SwitchListTile>(reminderSwitch()).onChanged, isNull);
      expect(tester.widget<SwitchListTile>(reminderSwitch()).value, isFalse);
      expect(timeDropdown(tester).onChanged, isNull);
    });
  });
}
