// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPreferencesEnvelope _$NotificationPreferencesEnvelopeFromJson(
  Map<String, dynamic> json,
) => NotificationPreferencesEnvelope(
  success: json['success'] as bool,
  data: NotificationPreferences.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$NotificationPreferencesEnvelopeToJson(
  NotificationPreferencesEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
