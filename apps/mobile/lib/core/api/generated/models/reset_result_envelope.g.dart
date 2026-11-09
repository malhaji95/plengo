// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetResultEnvelope _$ResetResultEnvelopeFromJson(Map<String, dynamic> json) =>
    ResetResultEnvelope(
      success: json['success'] as bool,
      data: ResetResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$ResetResultEnvelopeToJson(
  ResetResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
