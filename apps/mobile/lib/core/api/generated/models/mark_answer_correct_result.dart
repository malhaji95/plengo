// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_summary.dart';
import 'check_result.dart';

part 'mark_answer_correct_result.g.dart';

@JsonSerializable()
class MarkAnswerCorrectResult {
  const MarkAnswerCorrectResult({
    required this.questionId,
    required this.result,
    required this.attempt,
  });
  
  factory MarkAnswerCorrectResult.fromJson(Map<String, Object?> json) => _$MarkAnswerCorrectResultFromJson(json);
  
  final String questionId;
  final CheckResult result;
  final AttemptSummary attempt;

  Map<String, Object?> toJson() => _$MarkAnswerCorrectResultToJson(this);
}
