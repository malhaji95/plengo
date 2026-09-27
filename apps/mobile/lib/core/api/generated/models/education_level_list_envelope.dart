// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'education_level_list.dart';

part 'education_level_list_envelope.g.dart';

@JsonSerializable()
class EducationLevelListEnvelope {
  const EducationLevelListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory EducationLevelListEnvelope.fromJson(Map<String, Object?> json) => _$EducationLevelListEnvelopeFromJson(json);
  
  final bool success;
  final EducationLevelList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$EducationLevelListEnvelopeToJson(this);
}
