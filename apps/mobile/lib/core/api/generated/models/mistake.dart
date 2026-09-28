// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'mistake_status.dart';
import 'mistake_type.dart';

part 'mistake.g.dart';

@JsonSerializable()
class Mistake {
  const Mistake({
    required this.questionId,
    required this.type,
    required this.questionText,
    required this.subjectId,
    required this.subjectNameAr,
    required this.teacherTrackId,
    required this.trackTitleAr,
    required this.unitId,
    required this.unitNameAr,
    required this.lessonId,
    required this.lessonNameAr,
    required this.status,
    required this.wrongCount,
    required this.correctStreak,
    required this.firstWrongAt,
    required this.lastWrongAt,
  });
  
  factory Mistake.fromJson(Map<String, Object?> json) => _$MistakeFromJson(json);
  
  final String questionId;
  final MistakeType type;
  final String questionText;
  final String subjectId;
  final String subjectNameAr;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? trackTitleAr;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? unitNameAr;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  @JsonKey(includeIfNull: true)
  final String? lessonNameAr;
  final MistakeStatus status;
  final int wrongCount;
  final int correctStreak;
  final String firstWrongAt;
  final String lastWrongAt;

  Map<String, Object?> toJson() => _$MistakeToJson(this);
}
