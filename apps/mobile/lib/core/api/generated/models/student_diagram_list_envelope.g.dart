// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_diagram_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDiagramListEnvelope _$StudentDiagramListEnvelopeFromJson(
  Map<String, dynamic> json,
) => StudentDiagramListEnvelope(
  success: json['success'] as bool,
  data: StudentDiagramList.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$StudentDiagramListEnvelopeToJson(
  StudentDiagramListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
