// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteConfigEnvelope _$RemoteConfigEnvelopeFromJson(
  Map<String, dynamic> json,
) => RemoteConfigEnvelope(
  success: json['success'] as bool,
  data: RemoteConfig.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$RemoteConfigEnvelopeToJson(
  RemoteConfigEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
