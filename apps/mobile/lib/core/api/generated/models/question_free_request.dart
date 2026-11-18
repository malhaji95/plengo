// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'question_free_request_mode.dart';

part 'question_free_request.g.dart';

@JsonSerializable()
class QuestionFreeRequest {
  const QuestionFreeRequest({
    required this.mode,
  });
  
  factory QuestionFreeRequest.fromJson(Map<String, Object?> json) => _$QuestionFreeRequestFromJson(json);
  
  final QuestionFreeRequestMode mode;

  Map<String, Object?> toJson() => _$QuestionFreeRequestToJson(this);
}
