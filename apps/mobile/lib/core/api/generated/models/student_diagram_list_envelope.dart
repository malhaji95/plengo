// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_diagram_list.dart';

part 'student_diagram_list_envelope.g.dart';

@JsonSerializable()
class StudentDiagramListEnvelope {
  const StudentDiagramListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentDiagramListEnvelope.fromJson(Map<String, Object?> json) => _$StudentDiagramListEnvelopeFromJson(json);
  
  final bool success;
  final StudentDiagramList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentDiagramListEnvelopeToJson(this);
}
