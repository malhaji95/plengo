// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notification_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNotificationPreferences _$UpdateNotificationPreferencesFromJson(
  Map<String, dynamic> json,
) => UpdateNotificationPreferences(
  learning: json['learning'] as bool?,
  promotions: json['promotions'] as bool?,
  reminderTime: json['reminderTime'] as String?,
);

Map<String, dynamic> _$UpdateNotificationPreferencesToJson(
  UpdateNotificationPreferences instance,
) => <String, dynamic>{
  'learning': ?instance.learning,
  'promotions': ?instance.promotions,
  'reminderTime': ?instance.reminderTime,
};
