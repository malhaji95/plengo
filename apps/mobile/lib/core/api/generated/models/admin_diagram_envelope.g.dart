// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_diagram_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDiagramEnvelope _$AdminDiagramEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminDiagramEnvelope(
  success: json['success'] as bool,
  data: AdminDiagram.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$AdminDiagramEnvelopeToJson(
  AdminDiagramEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
