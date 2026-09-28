// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'teacher_detail.dart';
import 'teacher_track.dart';

part 'teacher_profile.g.dart';

@JsonSerializable()
class TeacherProfile {
  const TeacherProfile({required this.teacher, required this.tracks});

  factory TeacherProfile.fromJson(Map<String, Object?> json) => _$TeacherProfileFromJson(json);

  final TeacherDetail teacher;
  final List<TeacherTrack> tracks;

  Map<String, Object?> toJson() => _$TeacherProfileToJson(this);
}
