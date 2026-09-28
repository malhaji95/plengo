// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_question.dart';

part 'student_question_envelope.g.dart';

@JsonSerializable()
class StudentQuestionEnvelope {
  const StudentQuestionEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentQuestionEnvelope.fromJson(Map<String, Object?> json) => _$StudentQuestionEnvelopeFromJson(json);
  
  final bool success;
  final StudentQuestion data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentQuestionEnvelopeToJson(this);
}
