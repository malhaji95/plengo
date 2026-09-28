// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'goal_settings.dart';

part 'goal_settings_envelope.g.dart';

@JsonSerializable()
class GoalSettingsEnvelope {
  const GoalSettingsEnvelope({required this.success, required this.data, required this.error});

  factory GoalSettingsEnvelope.fromJson(Map<String, Object?> json) => _$GoalSettingsEnvelopeFromJson(json);

  final bool success;
  final GoalSettings data;
  final dynamic error;

  Map<String, Object?> toJson() => _$GoalSettingsEnvelopeToJson(this);
}
