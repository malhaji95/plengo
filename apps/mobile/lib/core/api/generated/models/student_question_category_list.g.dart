// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_question_category_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentQuestionCategoryList _$StudentQuestionCategoryListFromJson(
  Map<String, dynamic> json,
) => StudentQuestionCategoryList(
  items: (json['items'] as List<dynamic>)
      .map((e) => StudentQuestionCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  uncategorized: Uncategorized.fromJson(
    json['uncategorized'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$StudentQuestionCategoryListToJson(
  StudentQuestionCategoryList instance,
) => <String, dynamic>{
  'items': instance.items,
  'uncategorized': instance.uncategorized,
};
