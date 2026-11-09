// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_quiz_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuizListEnvelope _$StudentQuizListEnvelopeFromJson(
  Map<String, dynamic> json,
) => StudentQuizListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => StudentQuiz.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$StudentQuizListEnvelopeToJson(
  StudentQuizListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
