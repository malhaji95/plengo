// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'banner_action.dart';
import 'notification_type.dart';

part 'student_notification.g.dart';

@JsonSerializable()
class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.bodyAr,
    required this.action,
    required this.actionTarget,
    required this.createdAt,
    required this.readAt,
  });

  factory StudentNotification.fromJson(Map<String, Object?> json) => _$StudentNotificationFromJson(json);

  final String id;
  final NotificationType type;
  final String titleAr;
  final String bodyAr;
  final BannerAction action;
  @JsonKey(includeIfNull: true)
  final String? actionTarget;
  final String createdAt;
  @JsonKey(includeIfNull: true)
  final String? readAt;

  Map<String, Object?> toJson() => _$StudentNotificationToJson(this);
}
