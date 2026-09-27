// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'university_list.dart';

part 'university_list_envelope.g.dart';

@JsonSerializable()
class UniversityListEnvelope {
  const UniversityListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory UniversityListEnvelope.fromJson(Map<String, Object?> json) => _$UniversityListEnvelopeFromJson(json);
  
  final bool success;
  final UniversityList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UniversityListEnvelopeToJson(this);
}
