// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherListEnvelope _$TeacherListEnvelopeFromJson(Map<String, dynamic> json) => TeacherListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>).map((e) => Teacher.fromJson(e as Map<String, dynamic>)).toList(),
  error: json['error'],
);

Map<String, dynamic> _$TeacherListEnvelopeToJson(TeacherListEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
