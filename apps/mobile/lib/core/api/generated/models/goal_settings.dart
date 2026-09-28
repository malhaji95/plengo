// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'goal_settings.g.dart';

@JsonSerializable()
class GoalSettings {
  const GoalSettings({
    required this.dailyGoal,
  });
  
  factory GoalSettings.fromJson(Map<String, Object?> json) => _$GoalSettingsFromJson(json);
  
  final int dailyGoal;

  Map<String, Object?> toJson() => _$GoalSettingsToJson(this);
}
