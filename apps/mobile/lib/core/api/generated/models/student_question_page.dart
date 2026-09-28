// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_question.dart';

part 'student_question_page.g.dart';

@JsonSerializable()
class StudentQuestionPage {
  const StudentQuestionPage({
    required this.items,
    required this.nextCursor,
    required this.totalCount,
    required this.accessibleCount,
  });

  factory StudentQuestionPage.fromJson(Map<String, Object?> json) => _$StudentQuestionPageFromJson(json);

  final List<StudentQuestion> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;
  final int totalCount;
  final int accessibleCount;

  Map<String, Object?> toJson() => _$StudentQuestionPageToJson(this);
}
