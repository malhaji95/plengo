// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'content_count.dart';
import 'scope_access.dart';
import 'subject.dart';
import 'teacher.dart';
import 'teacher_track.dart';

part 'track_detail.g.dart';

@JsonSerializable()
class TrackDetail {
  const TrackDetail({
    required this.track,
    required this.teacher,
    required this.subject,
    required this.access,
    required this.questionCount,
    required this.deckCount,
  });
  
  factory TrackDetail.fromJson(Map<String, Object?> json) => _$TrackDetailFromJson(json);
  
  final TeacherTrack track;
  final Teacher teacher;
  final Subject subject;
  final ScopeAccess access;
  final ContentCount questionCount;
  final ContentCount deckCount;

  Map<String, Object?> toJson() => _$TrackDetailToJson(this);
}
