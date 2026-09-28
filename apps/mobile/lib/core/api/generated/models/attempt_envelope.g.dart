// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptEnvelope _$AttemptEnvelopeFromJson(Map<String, dynamic> json) =>
    AttemptEnvelope(
      success: json['success'] as bool,
      data: Attempt.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$AttemptEnvelopeToJson(AttemptEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
