// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_with_lessons_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitWithLessonsEnvelope _$UnitWithLessonsEnvelopeFromJson(Map<String, dynamic> json) => UnitWithLessonsEnvelope(
  success: json['success'] as bool,
  data: UnitWithLessons.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$UnitWithLessonsEnvelopeToJson(UnitWithLessonsEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
