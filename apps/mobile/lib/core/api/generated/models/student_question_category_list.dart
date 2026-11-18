// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_question_category.dart';
import 'uncategorized.dart';

part 'student_question_category_list.g.dart';

@JsonSerializable()
class StudentQuestionCategoryList {
  const StudentQuestionCategoryList({
    required this.items,
    required this.uncategorized,
  });
  
  factory StudentQuestionCategoryList.fromJson(Map<String, Object?> json) => _$StudentQuestionCategoryListFromJson(json);
  
  final List<StudentQuestionCategory> items;
  final Uncategorized uncategorized;

  Map<String, Object?> toJson() => _$StudentQuestionCategoryListToJson(this);
}
