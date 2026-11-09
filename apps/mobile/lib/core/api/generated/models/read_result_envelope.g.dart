// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadResultEnvelope _$ReadResultEnvelopeFromJson(Map<String, dynamic> json) =>
    ReadResultEnvelope(
      success: json['success'] as bool,
      data: ReadResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$ReadResultEnvelopeToJson(ReadResultEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
