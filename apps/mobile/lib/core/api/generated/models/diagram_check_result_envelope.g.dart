// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_check_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramCheckResultEnvelope _$DiagramCheckResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => DiagramCheckResultEnvelope(
  success: json['success'] as bool,
  data: DiagramCheckResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$DiagramCheckResultEnvelopeToJson(
  DiagramCheckResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
