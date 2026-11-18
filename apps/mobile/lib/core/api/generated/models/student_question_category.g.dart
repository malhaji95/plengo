// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionCategory _$StudentQuestionCategoryFromJson(
  Map<String, dynamic> json,
) => StudentQuestionCategory(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String?,
  parentId: json['parentId'] as String?,
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  sortOrder: (json['sortOrder'] as num).toInt(),
  questionCount: (json['questionCount'] as num).toInt(),
  accessibleCount: (json['accessibleCount'] as num).toInt(),
);

Map<String, dynamic> _$StudentQuestionCategoryToJson(
  StudentQuestionCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'subjectId': instance.subjectId,
  'parentId': instance.parentId,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'sortOrder': instance.sortOrder,
  'questionCount': instance.questionCount,
  'accessibleCount': instance.accessibleCount,
};
