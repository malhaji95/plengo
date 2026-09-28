// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_page_envelope.dart';
import '../models/notification_preferences_envelope.dart';
import '../models/push_token_request.dart';
import '../models/read_result_envelope.dart';
import '../models/registered_result_envelope.dart';
import '../models/revoke_push_token_request.dart';
import '../models/revoked_result_envelope.dart';
import '../models/update_notification_preferences.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) = _NotificationsClient;

  @GET('/api/v1/notifications')
  Future<NotificationPageEnvelope> listNotifications({
    @Query('limit') int? limit = 30,
    @Query('cursor') String? cursor,
  });

  @POST('/api/v1/notifications/{id}/read')
  Future<ReadResultEnvelope> markNotificationRead({@Path('id') required String id});

  @POST('/api/v1/notifications/read-all')
  Future<ReadResultEnvelope> markAllNotificationsRead();

  @GET('/api/v1/notifications/preferences')
  Future<NotificationPreferencesEnvelope> getNotificationPreferences();

  @PUT('/api/v1/notifications/preferences')
  Future<NotificationPreferencesEnvelope> updateNotificationPreferences({
    @Body() required UpdateNotificationPreferences body,
  });

  @POST('/api/v1/push-tokens')
  Future<RegisteredResultEnvelope> registerPushToken({@Body() required PushTokenRequest body});

  @POST('/api/v1/push-tokens/revoke')
  Future<RevokedResultEnvelope> revokePushToken({@Body() required RevokePushTokenRequest body});
}
