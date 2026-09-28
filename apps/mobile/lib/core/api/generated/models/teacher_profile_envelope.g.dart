// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_profile_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeacherProfileEnvelope _$TeacherProfileEnvelopeFromJson(Map<String, dynamic> json) => TeacherProfileEnvelope(
  success: json['success'] as bool,
  data: TeacherProfile.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$TeacherProfileEnvelopeToJson(TeacherProfileEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
