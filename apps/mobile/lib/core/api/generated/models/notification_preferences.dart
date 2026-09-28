// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_preferences.g.dart';

@JsonSerializable()
class NotificationPreferences {
  const NotificationPreferences({required this.learning, required this.promotions, required this.reminderTime});

  factory NotificationPreferences.fromJson(Map<String, Object?> json) => _$NotificationPreferencesFromJson(json);

  final bool learning;
  final bool promotions;
  final String reminderTime;

  Map<String, Object?> toJson() => _$NotificationPreferencesToJson(this);
}
