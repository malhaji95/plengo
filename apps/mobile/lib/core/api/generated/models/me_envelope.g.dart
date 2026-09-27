// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeEnvelope _$MeEnvelopeFromJson(Map<String, dynamic> json) => MeEnvelope(
  success: json['success'] as bool,
  data: Me.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$MeEnvelopeToJson(MeEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
