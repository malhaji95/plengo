// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionPage _$StudentQuestionPageFromJson(Map<String, dynamic> json) =>
    StudentQuestionPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => StudentQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      totalCount: (json['totalCount'] as num).toInt(),
      accessibleCount: (json['accessibleCount'] as num).toInt(),
    );

Map<String, dynamic> _$StudentQuestionPageToJson(
  StudentQuestionPage instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'totalCount': instance.totalCount,
  'accessibleCount': instance.accessibleCount,
};
