// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'academic_year_list.dart';

part 'academic_year_list_envelope.g.dart';

@JsonSerializable()
class AcademicYearListEnvelope {
  const AcademicYearListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AcademicYearListEnvelope.fromJson(Map<String, Object?> json) => _$AcademicYearListEnvelopeFromJson(json);
  
  final bool success;
  final AcademicYearList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AcademicYearListEnvelopeToJson(this);
}
