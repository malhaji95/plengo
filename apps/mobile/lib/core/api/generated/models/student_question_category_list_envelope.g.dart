// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_category_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionCategoryListEnvelope
_$StudentQuestionCategoryListEnvelopeFromJson(Map<String, dynamic> json) =>
    StudentQuestionCategoryListEnvelope(
      success: json['success'] as bool,
      data: StudentQuestionCategoryList.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
      error: json['error'],
    );

Map<String, dynamic> _$StudentQuestionCategoryListEnvelopeToJson(
  StudentQuestionCategoryListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
