// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_quiz_allowed_modes.dart';

part 'offline_quiz.g.dart';

@JsonSerializable()
class OfflineQuiz {
  const OfflineQuiz({
    required this.id,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.description,
    required this.allowedModes,
    required this.timeLimitSeconds,
    required this.passingScore,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.isFree,
    required this.questionIds,
  });

  factory OfflineQuiz.fromJson(Map<String, Object?> json) => _$OfflineQuizFromJson(json);

  final String id;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  final OfflineQuizAllowedModes allowedModes;
  @JsonKey(includeIfNull: true)
  final int? timeLimitSeconds;
  @JsonKey(includeIfNull: true)
  final int? passingScore;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool isFree;
  final List<String> questionIds;

  Map<String, Object?> toJson() => _$OfflineQuizToJson(this);
}
