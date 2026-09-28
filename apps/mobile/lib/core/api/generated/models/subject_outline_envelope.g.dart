// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_outline_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectOutlineEnvelope _$SubjectOutlineEnvelopeFromJson(Map<String, dynamic> json) => SubjectOutlineEnvelope(
  success: json['success'] as bool,
  data: SubjectOutline.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SubjectOutlineEnvelopeToJson(SubjectOutlineEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
