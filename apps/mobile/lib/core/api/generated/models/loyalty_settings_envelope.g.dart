// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_settings_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltySettingsEnvelope _$LoyaltySettingsEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltySettingsEnvelope(
  success: json['success'] as bool,
  data: LoyaltySettings.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltySettingsEnvelopeToJson(
  LoyaltySettingsEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
