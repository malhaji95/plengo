// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_quiz_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuizEnvelope _$StudentQuizEnvelopeFromJson(Map<String, dynamic> json) => StudentQuizEnvelope(
  success: json['success'] as bool,
  data: StudentQuiz.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$StudentQuizEnvelopeToJson(StudentQuizEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
