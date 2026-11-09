// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'content_count.dart';
import 'lesson.dart';
import 'scope_access.dart';
import 'subject.dart';
import 'subject_track.dart';
import 'unit_with_lessons.dart';

part 'subject_outline.g.dart';

@JsonSerializable()
class SubjectOutline {
  const SubjectOutline({
    required this.subject,
    required this.units,
    required this.lessons,
    required this.tracks,
    required this.access,
    required this.questionCount,
    required this.deckCount,
    required this.quizCount,
  });
  
  factory SubjectOutline.fromJson(Map<String, Object?> json) => _$SubjectOutlineFromJson(json);
  
  final Subject subject;
  final List<UnitWithLessons> units;
  final List<Lesson> lessons;
  final List<SubjectTrack> tracks;
  final ScopeAccess access;
  final ContentCount questionCount;
  final ContentCount deckCount;
  final ContentCount quizCount;

  Map<String, Object?> toJson() => _$SubjectOutlineToJson(this);
}
