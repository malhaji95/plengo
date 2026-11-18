// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_import_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramImportResultEnvelope _$DiagramImportResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => DiagramImportResultEnvelope(
  success: json['success'] as bool,
  data: DiagramImportResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$DiagramImportResultEnvelopeToJson(
  DiagramImportResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
