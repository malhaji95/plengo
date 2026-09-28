// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subject_accuracy.g.dart';

@JsonSerializable()
class SubjectAccuracy {
  const SubjectAccuracy({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.subjectId,
    required this.subjectNameAr,
    required this.teacherTrackId,
    required this.trackTitleAr,
  });
  
  factory SubjectAccuracy.fromJson(Map<String, Object?> json) => _$SubjectAccuracyFromJson(json);
  
  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final String subjectId;
  final String subjectNameAr;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? trackTitleAr;

  Map<String, Object?> toJson() => _$SubjectAccuracyToJson(this);
}
