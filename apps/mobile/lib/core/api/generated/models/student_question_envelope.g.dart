// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionEnvelope _$StudentQuestionEnvelopeFromJson(
  Map<String, dynamic> json,
) => StudentQuestionEnvelope(
  success: json['success'] as bool,
  data: StudentQuestion.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$StudentQuestionEnvelopeToJson(
  StudentQuestionEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
