// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'resume_item_activity_type.dart';

part 'resume_item.g.dart';

@JsonSerializable()
class ResumeItem {
  const ResumeItem({
    required this.subjectId,
    required this.subjectNameAr,
    required this.teacherTrackId,
    required this.trackTitleAr,
    required this.unitId,
    required this.unitNameAr,
    required this.lessonId,
    required this.lessonNameAr,
    required this.activityType,
    required this.itemId,
    required this.itemTitleAr,
    required this.attemptId,
    required this.lastActivityAt,
  });

  factory ResumeItem.fromJson(Map<String, Object?> json) => _$ResumeItemFromJson(json);

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
  final ResumeItemActivityType activityType;
  @JsonKey(includeIfNull: true)
  final String? itemId;
  @JsonKey(includeIfNull: true)
  final String? itemTitleAr;
  @JsonKey(includeIfNull: true)
  final String? attemptId;
  final String lastActivityAt;

  Map<String, Object?> toJson() => _$ResumeItemToJson(this);
}
