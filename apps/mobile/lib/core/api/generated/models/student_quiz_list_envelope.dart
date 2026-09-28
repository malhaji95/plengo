// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_quiz_list.dart';

part 'student_quiz_list_envelope.g.dart';

@JsonSerializable()
class StudentQuizListEnvelope {
  const StudentQuizListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentQuizListEnvelope.fromJson(Map<String, Object?> json) => _$StudentQuizListEnvelopeFromJson(json);
  
  final bool success;
  final StudentQuizList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentQuizListEnvelopeToJson(this);
}
