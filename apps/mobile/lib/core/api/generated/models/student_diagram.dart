// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_diagram.g.dart';

@JsonSerializable()
class StudentDiagram {
  const StudentDiagram({
    required this.id,
    required this.subjectId,
    required this.teacherTrackId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.labelCount,
    required this.isFree,
    required this.locked,
    required this.sortOrder,
  });
  
  factory StudentDiagram.fromJson(Map<String, Object?> json) => _$StudentDiagramFromJson(json);
  
  final String id;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String titleAr;
  final int labelCount;
  final bool isFree;
  final bool locked;
  final int sortOrder;

  Map<String, Object?> toJson() => _$StudentDiagramToJson(this);
}
