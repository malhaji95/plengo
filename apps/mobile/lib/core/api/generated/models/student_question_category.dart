// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_question_category.g.dart';

@JsonSerializable()
class StudentQuestionCategory {
  const StudentQuestionCategory({
    required this.id,
    required this.subjectId,
    required this.parentId,
    required this.code,
    required this.nameAr,
    required this.sortOrder,
    required this.questionCount,
    required this.accessibleCount,
  });
  
  factory StudentQuestionCategory.fromJson(Map<String, Object?> json) => _$StudentQuestionCategoryFromJson(json);
  
  final String id;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? parentId;
  final String code;
  final String nameAr;
  final int sortOrder;
  final int questionCount;
  final int accessibleCount;

  Map<String, Object?> toJson() => _$StudentQuestionCategoryToJson(this);
}
