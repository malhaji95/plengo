// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'accepted_answers.dart';
import 'offline_question_difficulty.dart';
import 'offline_question_type.dart';
import 'options.dart';

part 'offline_question.g.dart';

@JsonSerializable()
class OfflineQuestion {
  const OfflineQuestion({
    required this.id,
    required this.type,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.sortOrder,
    required this.difficulty,
    required this.isFree,
    required this.questionText,
    required this.explanation,
    required this.options,
    required this.acceptedAnswers,
  });
  
  factory OfflineQuestion.fromJson(Map<String, Object?> json) => _$OfflineQuestionFromJson(json);
  
  final String id;
  final OfflineQuestionType type;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final int sortOrder;
  @JsonKey(includeIfNull: true)
  final OfflineQuestionDifficulty? difficulty;
  final bool isFree;
  final String questionText;
  @JsonKey(includeIfNull: true)
  final String? explanation;
  final List<Options> options;
  final List<AcceptedAnswers> acceptedAnswers;

  Map<String, Object?> toJson() => _$OfflineQuestionToJson(this);
}
