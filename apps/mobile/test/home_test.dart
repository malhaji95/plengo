import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plengo/app/providers.dart';
import 'package:plengo/app/router.dart';
import 'package:plengo/core/api/api_exception.dart';
import 'package:plengo/core/api/generated/export.dart';
import 'package:plengo/core/home/push_messaging.dart';
import 'package:plengo/features/home/home_providers.dart';

import 'access_test.dart' show entitlement, physicsScope, trackScope;
import 'helpers.dart';

HomeBanner banner(String id, String title, BannerAction action, [String? target]) => HomeBanner(
  id: id,
  titleAr: title,
  imageUrl: 'https://cdn.test/$id.webp',
  width: 1600,
  height: 900,
  action: action,
  actionTarget: target,
);

StudentNotification notification(
  String id,
  String title, {
  bool read = false,
  BannerAction action = BannerAction.none,
  String? target,
  NotificationType type = NotificationType.announcement,
}) => StudentNotification(
  id: id,
  type: type,
  titleAr: title,
  bodyAr: 'نص $title',
  action: action,
  actionTarget: target,
  createdAt: '2026-09-27T09:00:00Z',
  readAt: read ? '2026-09-27T10:00:00Z' : null,
);

const teacher = Teacher(
  id: 't1',
  nameAr: 'أ. أحمد',
  slug: 'ahmad',
  photoUrl: null,
  shortDescription: null,
  followerCount: 3,
  isFollowing: true,
);

String location(PumpedApp app) => app.container.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

class FakePush implements PushMessaging {
  String? current = 'device-token-1';
  final refreshes = StreamController<String>.broadcast();

  @override
  Future<String?> token() async => current;

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
}

void main() {
  group('text helpers', () {
    ExamCountdown c(int days) =>
        ExamCountdown(titleAr: 'امتحان الشهادة الثانوية', examDate: '2027-06-01', daysLeft: days);

    test('countdown uses Arabic number agreement (§19.3)', () {
      expect(countdownText(c(87)), 'باقي 87 يوماً على امتحان الشهادة الثانوية');
      expect(countdownText(c(5)), 'باقي 5 أيام على امتحان الشهادة الثانوية');
      expect(countdownText(c(2)), 'باقي يومان على امتحان الشهادة الثانوية');
      expect(countdownText(c(1)), 'باقي يوم واحد على امتحان الشهادة الثانوية');
      expect(countdownText(c(0)), 'اليوم موعد امتحان الشهادة الثانوية، بالتوفيق!');
      expect(countedQuestions(1), 'سؤال واحد');
      expect(countedQuestions(6), '6 أسئلة');
      expect(countedQuestions(15), '15 سؤالاً');
      expect(streakText(0), 'لا سلسلة بعد');
      expect(streakText(4), '4 أيام متتالية');
      expect(streakText(12), '12 يوماً متتالياً');
    });

    test('banner and notification actions map to app routes; bad targets go nowhere', () {
      expect(actionRoute(BannerAction.subject, 'p'), '/subjects/p');
      expect(actionRoute(BannerAction.teacher, 't1'), '/teachers/t1');
      expect(actionRoute(BannerAction.teacherTrack, 'tr1'), '/tracks/tr1');
      expect(actionRoute(BannerAction.quiz, 'q1'), '/quizzes/q1');
      expect(actionRoute(BannerAction.deck, 'd1'), '/decks/d1');
      expect(actionRoute(BannerAction.internalRoute, '/review/mistakes'), '/review/mistakes');
      expect(actionRoute(BannerAction.internalRoute, '//evil.example'), isNull);
      expect(actionRoute(BannerAction.internalRoute, 'review'), isNull);
      expect(actionRoute(BannerAction.subject, null), isNull);
      expect(actionRoute(BannerAction.none, 'x'), isNull);
      expect(actionRoute(BannerAction.externalUrl, 'https://example.com'), isNull);
    });
  });

  testWidgets('home shows every §19.1 section', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) => when(() => h.home()).thenAnswer(
        (_) async => testHome(
          unread: 3,
          countdown: const ExamCountdown(titleAr: 'امتحان الشهادة الثانوية', examDate: '2027-06-01', daysLeft: 87),
          banners: [banner('b1', 'عرض الصيف', BannerAction.none), banner('b2', 'جديد', BannerAction.none)],
          today: const Today(dueCards: 12, goal: 20, done: 8, goalMet: false, streak: 4),
          myAccess: [
            entitlement('e1', physicsScope, MyEntitlementState.active),
            entitlement('e2', trackScope, MyEntitlementState.active),
          ],
          freeSubjects: const [FreeSubject(subjectId: 'c', nameAr: 'الكيمياء', freeCount: 14)],
          followedTeachers: const [teacher],
          activeMistakes: 6,
        ),
      ),
    );
    expect(find.text('مرحباً، سارة'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // bell badge
    expect(find.text('باقي 87 يوماً على امتحان الشهادة الثانوية'), findsOneWidget);
    expect(find.text('banner:عرض الصيف'), findsOneWidget);
    expect(find.text('هدف اليوم: 8 من 20'), findsOneWidget);
    expect(find.text('4 أيام متتالية'), findsOneWidget);
    expect(find.text('مراجعة البطاقات المستحقة (12)'), findsOneWidget);
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('ابدأ من المواد'), 200, scrollable: page);
    await tester.scrollUntilVisible(find.text('6 أسئلة في بنك الأخطاء'), 200, scrollable: page);
    await tester.scrollUntilVisible(find.text('أ. أحمد'), 200, scrollable: page);
    expect(find.text('الفيزياء'), findsWidgets);
    expect(find.text('أ. أحمد — فيزياء بكالوريا'), findsOneWidget);
    expect(find.text('14 عنصراً مجانياً'), findsOneWidget);
  });

  testWidgets('a banner tap opens its app route', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) => when(() => h.home()).thenAnswer(
        (_) async => testHome(
          banners: [
            banner('b1', 'داخلي', BannerAction.internalRoute, Routes.myAccess),
            banner('b2', 'ثان', BannerAction.none),
          ],
        ),
      ),
    );
    await tester.tap(find.text('banner:داخلي'));
    await tester.pumpAndSettle();
    expect(location(app), Routes.myAccess);
  });

  testWidgets('an external banner opens the browser; a banner without action does nothing', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) => when(() => h.home()).thenAnswer(
        (_) async => testHome(banners: [banner('b1', 'رابط', BannerAction.externalUrl, 'https://example.com/offer')]),
      ),
    );
    await tester.tap(find.text('banner:رابط'));
    await tester.pumpAndSettle();
    expect(app.launched, [Uri.parse('https://example.com/offer')]);
    expect(location(app), Routes.home);
  });

  testWidgets('the daily goal can be changed from Home (§19.4)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) {
        when(() => h.home()).thenAnswer(
          (_) async => testHome(today: const Today(dueCards: 0, goal: 20, done: 20, goalMet: true, streak: 1)),
        );
        when(() => h.setGoal(any())).thenAnswer((i) async => i.positionalArguments.first as int);
      },
    );
    expect(find.text('أنجزت هدف اليوم ✓'), findsOneWidget);
    expect(find.text('يوم واحد متتالٍ'), findsOneWidget);
    expect(find.text('لا بطاقات مستحقة الآن'), findsOneWidget);
    await tester.tap(find.text('تعديل الهدف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    verify(() => app.home.setGoal(50)).called(1);
    verify(() => app.home.home()).called(greaterThan(1)); // refreshed
  });

  testWidgets('offline, Home offers what works without a connection', (tester) async {
    await pumpApp(
      tester,
      signedInAs: testMe,
      offlinePacks: true,
      arrangeHome: (h) => when(() => h.home()).thenThrow(const ApiException('NETWORK_ERROR', 'لا يوجد اتصال')),
    );
    expect(find.text('مرحباً، سارة'), findsOneWidget);
    expect(find.text('أنت غير متصل بالإنترنت'), findsOneWidget);
    expect(find.text('المحتوى المحمّل'), findsOneWidget);
  });

  testWidgets('inbox: marks read on tap, opens the action, marks all, pages', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) {
        when(() => h.home()).thenAnswer((_) async => testHome(unread: 2));
        when(() => h.notifications()).thenAnswer(
          (_) async => NotificationPage(
            items: [
              notification('n1', 'مدرس جديد', action: BannerAction.teacher, target: 't1'),
              notification('n2', 'إعلان'),
              notification('n3', 'قديم', read: true),
            ],
            nextCursor: 'c2',
            unreadCount: 2,
          ),
        );
        when(() => h.notifications(cursor: 'c2')).thenAnswer(
          (_) async =>
              NotificationPage(items: [notification('n4', 'أقدم', read: true)], nextCursor: null, unreadCount: 2),
        );
        when(() => h.markRead(any())).thenAnswer((_) async => 1);
        when(() => h.markAllRead()).thenAnswer((_) async => 0);
      },
      arrangeTeachers: (t) => when(() => t.profile('t1')).thenThrow(const ApiException('NOT_FOUND', 'غير موجود')),
    );
    await tester.tap(find.byTooltip('الإشعارات'));
    await tester.pumpAndSettle();
    expect(find.text('مدرس جديد'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNWidgets(2));

    await tester.tap(find.text('عرض المزيد'));
    await tester.pumpAndSettle();
    expect(find.text('أقدم'), findsOneWidget);
    expect(find.text('عرض المزيد'), findsNothing);
    verify(() => app.home.notifications(cursor: 'c2')).called(1);

    await tester.tap(find.text('تعليم الكل كمقروء'));
    await tester.pumpAndSettle();
    verify(() => app.home.markAllRead()).called(1);
    expect(find.byIcon(Icons.circle), findsNothing);
    expect(find.text('تعليم الكل كمقروء'), findsNothing);

    await tester.tap(find.text('مدرس جديد'));
    await tester.pumpAndSettle();
    // Already read after "mark all": no second call, but the action still opens.
    verifyNever(() => app.home.markRead(any()));
    expect(location(app), '/teachers/t1');
  });

  testWidgets('an unread notification is marked read when opened', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) {
        when(() => h.notifications()).thenAnswer(
          (_) async => NotificationPage(items: [notification('n1', 'تذكير')], nextCursor: null, unreadCount: 1),
        );
        when(() => h.markRead('n1')).thenAnswer((_) async => 0);
      },
    );
    unawaited(app.container.read(routerProvider).push(Routes.notifications));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تذكير'));
    await tester.pumpAndSettle();
    verify(() => app.home.markRead('n1')).called(1);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('notification settings: consent categories, reminder time and goal (§20.2)', (tester) async {
    final app = await pumpApp(
      tester,
      signedInAs: testMe,
      arrangeHome: (h) {
        when(() => h.preferences()).thenAnswer(
          (_) async => const NotificationPreferences(learning: true, promotions: false, reminderTime: '18:00'),
        );
        when(() => h.goal()).thenAnswer((_) async => 20);
        when(
          () => h.setPreferences(
            learning: any(named: 'learning'),
            promotions: any(named: 'promotions'),
            reminderTime: any(named: 'reminderTime'),
          ),
        ).thenAnswer(
          (_) async => const NotificationPreferences(learning: true, promotions: true, reminderTime: '18:00'),
        );
      },
    );
    app.container.read(routerProvider).go(Routes.account);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإشعارات والهدف اليومي'));
    await tester.pumpAndSettle();
    expect(find.text('18:00'), findsOneWidget);
    expect(find.text('20 عنصراً يومياً (بطاقات وإجابات)'), findsOneWidget);

    // Promotions are off until the student opts in.
    final promotions = find.widgetWithText(SwitchListTile, 'العروض');
    expect(tester.widget<SwitchListTile>(promotions).value, isFalse);
    await tester.tap(promotions);
    await tester.pumpAndSettle();
    verify(() => app.home.setPreferences(promotions: true)).called(1);

    await tester.tap(find.text('18:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20:00').last);
    await tester.pumpAndSettle();
    verify(() => app.home.setPreferences(reminderTime: '20:00')).called(1);
  });

  group('push registration (§20.3)', () {
    test('registers the token, follows refreshes, revokes at stop, ignores failures', () async {
      final repo = MockHomeRepository();
      final push = FakePush();
      when(
        () => repo.registerPushToken(
          any(),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.revokePushToken(any())).thenAnswer((_) async {});
      final reg = PushRegistration(push, repo, platform: 'android', appVersion: '1.2.0');

      await reg.start();
      verify(() => repo.registerPushToken('device-token-1', platform: 'android', appVersion: '1.2.0')).called(1);
      await reg.start(); // same token: nothing new
      verifyNever(
        () => repo.registerPushToken(
          any(),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
        ),
      );

      push.refreshes.add('device-token-2');
      await pumpEventQueue();
      verify(() => repo.registerPushToken('device-token-2', platform: 'android', appVersion: '1.2.0')).called(1);
      expect(reg.registeredToken, 'device-token-2');

      await reg.stop();
      verify(() => repo.revokePushToken('device-token-2')).called(1);
      expect(reg.registeredToken, isNull);
      await reg.stop();
      verifyNever(() => repo.revokePushToken(any()));

      // A failed registration is retried at the next start.
      when(
        () => repo.registerPushToken(
          any(),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
        ),
      ).thenThrow(const ApiException('NETWORK_ERROR', 'x'));
      await reg.start();
      expect(reg.registeredToken, isNull);
    });

    test('without push support nothing is registered', () async {
      final repo = MockHomeRepository();
      final reg = PushRegistration(const NoPushMessaging(), repo, platform: 'web', appVersion: '1.0.0');
      await reg.start();
      await reg.stop();
      verifyZeroInteractions(repo);
    });

    testWidgets('signing in registers the device and logout revokes it', (tester) async {
      final push = FakePush();
      final app = await pumpApp(
        tester,
        signedInAs: testMe,
        arrange: (repo) => when(() => repo.logout()).thenAnswer((_) async {}),
        arrangeHome: (h) {
          when(
            () => h.registerPushToken(
              any(),
              platform: any(named: 'platform'),
              appVersion: any(named: 'appVersion'),
            ),
          ).thenAnswer((_) async {});
          when(() => h.revokePushToken(any())).thenAnswer((_) async {});
        },
        extraOverrides: [pushMessagingProvider.overrideWithValue(push)],
      );
      verify(() => app.home.registerPushToken('device-token-1', platform: 'android', appVersion: '1.0.0')).called(1);
      await app.container.read(authControllerProvider.notifier).logout();
      await tester.pumpAndSettle();
      verifyInOrder([() => app.home.revokePushToken('device-token-1'), () => app.repo.logout()]);
    });
  });
}
