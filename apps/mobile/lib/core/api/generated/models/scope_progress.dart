// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lesson_progress.dart';
import 'unit_progress.dart';

part 'scope_progress.g.dart';

@JsonSerializable()
class ScopeProgress {
  const ScopeProgress({
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.questionsTotal,
    required this.quizzesCompleted,
    required this.quizzesTotal,
    required this.flashcardsStudied,
    required this.flashcardsTotal,
    required this.completionPercent,
    required this.subjectId,
    required this.teacherTrackId,
    required this.lastActivityAt,
    required this.units,
    required this.lessons,
  });

  factory ScopeProgress.fromJson(Map<String, Object?> json) => _$ScopeProgressFromJson(json);

  final int questionsAttempted;
  final int questionsCorrect;
  final int questionsTotal;
  final int quizzesCompleted;
  final int quizzesTotal;
  final int flashcardsStudied;
  final int flashcardsTotal;
  final int completionPercent;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? lastActivityAt;
  final List<UnitProgress> units;
  final List<LessonProgress> lessons;

  Map<String, Object?> toJson() => _$ScopeProgressToJson(this);
}
