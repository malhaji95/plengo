// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'faculty_list.dart';

part 'faculty_list_envelope.g.dart';

@JsonSerializable()
class FacultyListEnvelope {
  const FacultyListEnvelope({required this.success, required this.data, required this.error});

  factory FacultyListEnvelope.fromJson(Map<String, Object?> json) => _$FacultyListEnvelopeFromJson(json);

  final bool success;
  final FacultyList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$FacultyListEnvelopeToJson(this);
}
