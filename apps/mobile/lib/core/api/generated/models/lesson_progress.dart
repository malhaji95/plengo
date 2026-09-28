// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lesson_progress.g.dart';

@JsonSerializable()
class LessonProgress {
  const LessonProgress({
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.questionsTotal,
    required this.quizzesCompleted,
    required this.quizzesTotal,
    required this.flashcardsStudied,
    required this.flashcardsTotal,
    required this.completionPercent,
    required this.lessonId,
  });

  factory LessonProgress.fromJson(Map<String, Object?> json) => _$LessonProgressFromJson(json);

  final int questionsAttempted;
  final int questionsCorrect;
  final int questionsTotal;
  final int quizzesCompleted;
  final int quizzesTotal;
  final int flashcardsStudied;
  final int flashcardsTotal;
  final int completionPercent;
  final String lessonId;

  Map<String, Object?> toJson() => _$LessonProgressToJson(this);
}
