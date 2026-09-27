// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subject_track.g.dart';

@JsonSerializable()
class SubjectTrack {
  const SubjectTrack({
    required this.id,
    required this.teacherId,
    required this.teacherNameAr,
    required this.teacherPhotoUrl,
    required this.titleAr,
    required this.description,
    required this.coverUrl,
  });
  
  factory SubjectTrack.fromJson(Map<String, Object?> json) => _$SubjectTrackFromJson(json);
  
  final String id;
  final String teacherId;
  final String teacherNameAr;
  @JsonKey(includeIfNull: true)
  final String? teacherPhotoUrl;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  @JsonKey(includeIfNull: true)
  final String? coverUrl;

  Map<String, Object?> toJson() => _$SubjectTrackToJson(this);
}
