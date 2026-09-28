// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lesson.dart';

part 'lesson_envelope.g.dart';

@JsonSerializable()
class LessonEnvelope {
  const LessonEnvelope({required this.success, required this.data, required this.error});

  factory LessonEnvelope.fromJson(Map<String, Object?> json) => _$LessonEnvelopeFromJson(json);

  final bool success;
  final Lesson data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LessonEnvelopeToJson(this);
}
