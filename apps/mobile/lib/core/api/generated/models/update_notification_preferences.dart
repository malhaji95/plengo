// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_notification_preferences.g.dart';

@JsonSerializable()
class UpdateNotificationPreferences {
  const UpdateNotificationPreferences({this.learning, this.promotions, this.reminderTime});

  factory UpdateNotificationPreferences.fromJson(Map<String, Object?> json) =>
      _$UpdateNotificationPreferencesFromJson(json);

  @JsonKey(includeIfNull: false)
  final bool? learning;
  @JsonKey(includeIfNull: false)
  final bool? promotions;
  @JsonKey(includeIfNull: false)
  final String? reminderTime;

  Map<String, Object?> toJson() => _$UpdateNotificationPreferencesToJson(this);
}
