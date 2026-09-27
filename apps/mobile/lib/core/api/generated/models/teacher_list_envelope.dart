// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'teacher_list.dart';

part 'teacher_list_envelope.g.dart';

@JsonSerializable()
class TeacherListEnvelope {
  const TeacherListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory TeacherListEnvelope.fromJson(Map<String, Object?> json) => _$TeacherListEnvelopeFromJson(json);
  
  final bool success;
  final TeacherList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$TeacherListEnvelopeToJson(this);
}
