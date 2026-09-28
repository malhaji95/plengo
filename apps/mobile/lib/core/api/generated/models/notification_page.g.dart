// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) => NotificationPage(
  items: (json['items'] as List<dynamic>).map((e) => StudentNotification.fromJson(e as Map<String, dynamic>)).toList(),
  nextCursor: json['nextCursor'] as String?,
  unreadCount: (json['unreadCount'] as num).toInt(),
);

Map<String, dynamic> _$NotificationPageToJson(NotificationPage instance) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'unreadCount': instance.unreadCount,
};
