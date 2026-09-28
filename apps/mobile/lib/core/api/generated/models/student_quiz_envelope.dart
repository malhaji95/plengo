// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_quiz.dart';

part 'student_quiz_envelope.g.dart';

@JsonSerializable()
class StudentQuizEnvelope {
  const StudentQuizEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentQuizEnvelope.fromJson(Map<String, Object?> json) => _$StudentQuizEnvelopeFromJson(json);
  
  final bool success;
  final StudentQuiz data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentQuizEnvelopeToJson(this);
}
