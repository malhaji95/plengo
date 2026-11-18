// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_diagram_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDiagramPageEnvelope _$AdminDiagramPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminDiagramPageEnvelope(
  success: json['success'] as bool,
  data: AdminDiagramPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$AdminDiagramPageEnvelopeToJson(
  AdminDiagramPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
