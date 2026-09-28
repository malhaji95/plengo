// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revoked_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevokedResultEnvelope _$RevokedResultEnvelopeFromJson(Map<String, dynamic> json) => RevokedResultEnvelope(
  success: json['success'] as bool,
  data: RevokedResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$RevokedResultEnvelopeToJson(RevokedResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
