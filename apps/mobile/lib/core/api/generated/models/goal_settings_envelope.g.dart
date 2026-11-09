// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_settings_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GoalSettingsEnvelope _$GoalSettingsEnvelopeFromJson(
  Map<String, dynamic> json,
) => GoalSettingsEnvelope(
  success: json['success'] as bool,
  data: GoalSettings.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$GoalSettingsEnvelopeToJson(
  GoalSettingsEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
