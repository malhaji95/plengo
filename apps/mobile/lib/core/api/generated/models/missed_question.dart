// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'missed_question.g.dart';

@JsonSerializable()
class MissedQuestion {
  const MissedQuestion({
    required this.questionId,
    required this.questionText,
    required this.subjectNameAr,
    required this.wrongCount,
  });

  factory MissedQuestion.fromJson(Map<String, Object?> json) => _$MissedQuestionFromJson(json);

  final String questionId;
  final String questionText;
  final String subjectNameAr;
  final int wrongCount;

  Map<String, Object?> toJson() => _$MissedQuestionToJson(this);
}
