import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/generated/export.dart';

/// Home, daily goal, notification inbox and preferences (spec §19, §20).
class HomeRepository {
  HomeRepository(this.client);

  final ApiClient client;

  Future<Home> home() => guardApi(() async => (await client.api.home.getHome()).data);

  Future<int> goal() => guardApi(() async => (await client.api.home.getGoalSettings()).data.dailyGoal);

  Future<int> setGoal(int dailyGoal) => guardApi(
    () async => (await client.api.home.updateGoalSettings(body: GoalSettings(dailyGoal: dailyGoal))).data.dailyGoal,
  );

  Future<NotificationPage> notifications({String? cursor}) =>
      guardApi(() async => (await client.api.notifications.listNotifications(cursor: cursor)).data);

  /// Returns the unread count after the change.
  Future<int> markRead(String id) =>
      guardApi(() async => (await client.api.notifications.markNotificationRead(id: id)).data.unreadCount);

  Future<int> markAllRead() =>
      guardApi(() async => (await client.api.notifications.markAllNotificationsRead()).data.unreadCount);

  Future<NotificationPreferences> preferences() =>
      guardApi(() async => (await client.api.notifications.getNotificationPreferences()).data);

  Future<NotificationPreferences> setPreferences({bool? learning, bool? promotions, String? reminderTime}) => guardApi(
    () async => (await client.api.notifications.updateNotificationPreferences(
      body: UpdateNotificationPreferences(learning: learning, promotions: promotions, reminderTime: reminderTime),
    )).data,
  );

  Future<void> registerPushToken(String token, {required String platform, required String appVersion}) => guardApi(
    () => client.api.notifications.registerPushToken(
      body: PushTokenRequest(
        token: token,
        platform: PushTokenRequestPlatform.values.firstWhere(
          (p) => p.json == platform,
          orElse: () => PushTokenRequestPlatform.android,
        ),
        appVersion: appVersion,
      ),
    ),
  );

  Future<void> revokePushToken(String token) =>
      guardApi(() => client.api.notifications.revokePushToken(body: RevokePushTokenRequest(token: token)));
}
