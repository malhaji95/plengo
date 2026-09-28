// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'submit_answer.dart';

part 'submit_attempt_request.g.dart';

@JsonSerializable()
class SubmitAttemptRequest {
  const SubmitAttemptRequest({
    required this.answers,
    this.timeSpentMs,
  });
  
  factory SubmitAttemptRequest.fromJson(Map<String, Object?> json) => _$SubmitAttemptRequestFromJson(json);
  
  final List<SubmitAnswer> answers;
  @JsonKey(includeIfNull: false)
  final int? timeSpentMs;

  Map<String, Object?> toJson() => _$SubmitAttemptRequestToJson(this);
}
