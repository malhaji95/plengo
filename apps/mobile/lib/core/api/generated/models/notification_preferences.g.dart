// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferences _$NotificationPreferencesFromJson(Map<String, dynamic> json) => NotificationPreferences(
  learning: json['learning'] as bool,
  promotions: json['promotions'] as bool,
  reminderTime: json['reminderTime'] as String,
);

Map<String, dynamic> _$NotificationPreferencesToJson(NotificationPreferences instance) => <String, dynamic>{
  'learning': instance.learning,
  'promotions': instance.promotions,
  'reminderTime': instance.reminderTime,
};
