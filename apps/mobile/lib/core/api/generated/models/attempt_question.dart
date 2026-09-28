// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_option.dart';
import 'attempt_question_type.dart';
import 'check_result.dart';

part 'attempt_question.g.dart';

@JsonSerializable()
class AttemptQuestion {
  const AttemptQuestion({
    required this.questionId,
    required this.type,
    required this.unitId,
    required this.lessonId,
    required this.questionText,
    required this.options,
    required this.selectedOptionId,
    required this.writtenAnswer,
    required this.flagged,
    required this.answeredAt,
    required this.timeSpentMs,
    required this.result,
  });
  
  factory AttemptQuestion.fromJson(Map<String, Object?> json) => _$AttemptQuestionFromJson(json);
  
  final String questionId;
  final AttemptQuestionType type;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String questionText;
  final List<AttemptOption> options;
  @JsonKey(includeIfNull: true)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: true)
  final String? writtenAnswer;
  final bool flagged;
  @JsonKey(includeIfNull: true)
  final String? answeredAt;
  @JsonKey(includeIfNull: true)
  final int? timeSpentMs;
  @JsonKey(includeIfNull: true)
  final CheckResult? result;

  Map<String, Object?> toJson() => _$AttemptQuestionToJson(this);
}
