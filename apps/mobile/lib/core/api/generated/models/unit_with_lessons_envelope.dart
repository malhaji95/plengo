// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unit_with_lessons.dart';

part 'unit_with_lessons_envelope.g.dart';

@JsonSerializable()
class UnitWithLessonsEnvelope {
  const UnitWithLessonsEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory UnitWithLessonsEnvelope.fromJson(Map<String, Object?> json) => _$UnitWithLessonsEnvelopeFromJson(json);
  
  final bool success;
  final UnitWithLessons data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UnitWithLessonsEnvelopeToJson(this);
}
