// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonEnvelope _$LessonEnvelopeFromJson(Map<String, dynamic> json) =>
    LessonEnvelope(
      success: json['success'] as bool,
      data: Lesson.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$LessonEnvelopeToJson(LessonEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
