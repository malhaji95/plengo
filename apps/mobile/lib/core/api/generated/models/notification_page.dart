// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_notification.dart';

part 'notification_page.g.dart';

@JsonSerializable()
class NotificationPage {
  const NotificationPage({required this.items, required this.nextCursor, required this.unreadCount});

  factory NotificationPage.fromJson(Map<String, Object?> json) => _$NotificationPageFromJson(json);

  final List<StudentNotification> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;
  final int unreadCount;

  Map<String, Object?> toJson() => _$NotificationPageToJson(this);
}
