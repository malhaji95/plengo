// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'teacher_profile.dart';

part 'teacher_profile_envelope.g.dart';

@JsonSerializable()
class TeacherProfileEnvelope {
  const TeacherProfileEnvelope({required this.success, required this.data, required this.error});

  factory TeacherProfileEnvelope.fromJson(Map<String, Object?> json) => _$TeacherProfileEnvelopeFromJson(json);

  final bool success;
  final TeacherProfile data;
  final dynamic error;

  Map<String, Object?> toJson() => _$TeacherProfileEnvelopeToJson(this);
}
