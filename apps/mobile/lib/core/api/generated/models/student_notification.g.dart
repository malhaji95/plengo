// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentNotification _$StudentNotificationFromJson(Map<String, dynamic> json) => StudentNotification(
  id: json['id'] as String,
  type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
  titleAr: json['titleAr'] as String,
  bodyAr: json['bodyAr'] as String,
  action: $enumDecode(_$BannerActionEnumMap, json['action']),
  actionTarget: json['actionTarget'] as String?,
  createdAt: json['createdAt'] as String,
  readAt: json['readAt'] as String?,
);

Map<String, dynamic> _$StudentNotificationToJson(StudentNotification instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'titleAr': instance.titleAr,
  'bodyAr': instance.bodyAr,
  'action': instance.action,
  'actionTarget': instance.actionTarget,
  'createdAt': instance.createdAt,
  'readAt': instance.readAt,
};

const _$NotificationTypeEnumMap = {
  NotificationType.newContent: 'new_content',
  NotificationType.teacherUpdate: 'teacher_update',
  NotificationType.dueReminder: 'due_reminder',
  NotificationType.studyReminder: 'study_reminder',
  NotificationType.announcement: 'announcement',
  NotificationType.promotion: 'promotion',
  NotificationType.reportResolved: 'report_resolved',
};

const _$BannerActionEnumMap = {
  BannerAction.subject: 'subject',
  BannerAction.teacher: 'teacher',
  BannerAction.teacherTrack: 'teacher_track',
  BannerAction.quiz: 'quiz',
  BannerAction.deck: 'deck',
  BannerAction.internalRoute: 'internal_route',
  BannerAction.externalUrl: 'external_url',
  BannerAction.none: 'none',
};
