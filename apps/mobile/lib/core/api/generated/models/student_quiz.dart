// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_quiz_allowed_modes.dart';

part 'student_quiz.g.dart';

@JsonSerializable()
class StudentQuiz {
  const StudentQuiz({
    required this.id,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.description,
    required this.allowedModes,
    required this.timeLimitSeconds,
    required this.passingScorePercent,
    required this.maxAttempts,
    required this.isMockExam,
    required this.allowOffline,
    required this.isFree,
    required this.sortOrder,
    required this.contentVersion,
    required this.totalCount,
    required this.accessibleCount,
    required this.lockedCount,
    required this.locked,
    required this.attemptsUsed,
    required this.bestScorePercent,
    required this.inProgressAttemptId,
  });
  
  factory StudentQuiz.fromJson(Map<String, Object?> json) => _$StudentQuizFromJson(json);
  
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
  final StudentQuizAllowedModes allowedModes;
  @JsonKey(includeIfNull: true)
  final int? timeLimitSeconds;
  @JsonKey(includeIfNull: true)
  final int? passingScorePercent;
  @JsonKey(includeIfNull: true)
  final int? maxAttempts;
  final bool isMockExam;
  final bool allowOffline;
  final bool isFree;
  final int sortOrder;
  final int contentVersion;
  final int totalCount;
  final int accessibleCount;
  final int lockedCount;
  final bool locked;
  final int attemptsUsed;
  @JsonKey(includeIfNull: true)
  final int? bestScorePercent;
  @JsonKey(includeIfNull: true)
  final String? inProgressAttemptId;

  Map<String, Object?> toJson() => _$StudentQuizToJson(this);
}
