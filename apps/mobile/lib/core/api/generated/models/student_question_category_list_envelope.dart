// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'student_question_category_list.dart';

part 'student_question_category_list_envelope.g.dart';

@JsonSerializable()
class StudentQuestionCategoryListEnvelope {
  const StudentQuestionCategoryListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory StudentQuestionCategoryListEnvelope.fromJson(Map<String, Object?> json) => _$StudentQuestionCategoryListEnvelopeFromJson(json);
  
  final bool success;
  final StudentQuestionCategoryList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StudentQuestionCategoryListEnvelopeToJson(this);
}
