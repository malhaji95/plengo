// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionPageEnvelope _$StudentQuestionPageEnvelopeFromJson(Map<String, dynamic> json) =>
    StudentQuestionPageEnvelope(
      success: json['success'] as bool,
      data: StudentQuestionPage.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$StudentQuestionPageEnvelopeToJson(StudentQuestionPageEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
