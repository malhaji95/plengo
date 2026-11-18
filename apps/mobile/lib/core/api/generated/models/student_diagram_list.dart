// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_diagram.dart';

part 'student_diagram_list.g.dart';

@JsonSerializable()
class StudentDiagramList {
  const StudentDiagramList({
    required this.items,
    required this.totalCount,
    required this.accessibleCount,
    required this.lockedCount,
  });
  
  factory StudentDiagramList.fromJson(Map<String, Object?> json) => _$StudentDiagramListFromJson(json);
  
  final List<StudentDiagram> items;
  final int totalCount;
  final int accessibleCount;
  final int lockedCount;

  Map<String, Object?> toJson() => _$StudentDiagramListToJson(this);
}
