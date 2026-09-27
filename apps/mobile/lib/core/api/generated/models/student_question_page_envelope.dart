// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_question_page.dart';

part 'student_question_page_envelope.g.dart';

@JsonSerializable()
class StudentQuestionPageEnvelope {
  const StudentQuestionPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentQuestionPageEnvelope.fromJson(Map<String, Object?> json) => _$StudentQuestionPageEnvelopeFromJson(json);
  
  final bool success;
  final StudentQuestionPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentQuestionPageEnvelopeToJson(this);
}
