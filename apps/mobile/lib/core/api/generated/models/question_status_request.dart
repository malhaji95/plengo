// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'question_status_request_status.dart';

part 'question_status_request.g.dart';

@JsonSerializable()
class QuestionStatusRequest {
  const QuestionStatusRequest({
    required this.status,
  });
  
  factory QuestionStatusRequest.fromJson(Map<String, Object?> json) => _$QuestionStatusRequestFromJson(json);
  
  final QuestionStatusRequestStatus status;

  Map<String, Object?> toJson() => _$QuestionStatusRequestToJson(this);
}
