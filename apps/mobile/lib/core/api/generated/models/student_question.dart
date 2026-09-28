// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_option.dart';
import 'student_question_difficulty.dart';
import 'student_question_type.dart';

part 'student_question.g.dart';

@JsonSerializable()
class StudentQuestion {
  const StudentQuestion({
    required this.id,
    required this.type,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.sortOrder,
    required this.difficulty,
    required this.isFree,
    required this.locked,
    required this.questionText,
    required this.options,
  });

  factory StudentQuestion.fromJson(Map<String, Object?> json) => _$StudentQuestionFromJson(json);

  final String id;
  final StudentQuestionType type;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final num sortOrder;
  @JsonKey(includeIfNull: true)
  final StudentQuestionDifficulty? difficulty;
  final bool isFree;
  final bool locked;
  @JsonKey(includeIfNull: true)
  final String? questionText;
  @JsonKey(includeIfNull: true)
  final List<StudentOption>? options;

  Map<String, Object?> toJson() => _$StudentQuestionToJson(this);
}
