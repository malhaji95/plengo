// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'teacher_track.g.dart';

@JsonSerializable()
class TeacherTrack {
  const TeacherTrack({
    required this.id,
    required this.teacherId,
    required this.teacherNameAr,
    required this.subjectId,
    required this.subjectNameAr,
    required this.educationLevelId,
    required this.titleAr,
    required this.slug,
    required this.description,
    required this.coverUrl,
  });

  factory TeacherTrack.fromJson(Map<String, Object?> json) => _$TeacherTrackFromJson(json);

  final String id;
  final String teacherId;
  final String teacherNameAr;
  final String subjectId;
  final String subjectNameAr;
  final String educationLevelId;
  final String titleAr;
  final String slug;
  @JsonKey(includeIfNull: true)
  final String? description;
  @JsonKey(includeIfNull: true)
  final String? coverUrl;

  Map<String, Object?> toJson() => _$TeacherTrackToJson(this);
}
