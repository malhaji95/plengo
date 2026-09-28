// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lesson_accuracy.g.dart';

@JsonSerializable()
class LessonAccuracy {
  const LessonAccuracy({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.lessonId,
    required this.lessonNameAr,
  });

  factory LessonAccuracy.fromJson(Map<String, Object?> json) => _$LessonAccuracyFromJson(json);

  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final String lessonId;
  final String lessonNameAr;

  Map<String, Object?> toJson() => _$LessonAccuracyToJson(this);
}
