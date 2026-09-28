// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sent_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentResultEnvelope _$SentResultEnvelopeFromJson(Map<String, dynamic> json) =>
    SentResultEnvelope(
      success: json['success'] as bool,
      data: SentResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SentResultEnvelopeToJson(SentResultEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
