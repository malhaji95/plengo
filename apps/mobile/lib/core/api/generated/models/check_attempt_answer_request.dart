// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'check_attempt_answer_request.g.dart';

@JsonSerializable()
class CheckAttemptAnswerRequest {
  const CheckAttemptAnswerRequest({this.selectedOptionId, this.writtenAnswer, this.timeSpentMs});

  factory CheckAttemptAnswerRequest.fromJson(Map<String, Object?> json) => _$CheckAttemptAnswerRequestFromJson(json);

  @JsonKey(includeIfNull: false)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: false)
  final String? writtenAnswer;
  @JsonKey(includeIfNull: false)
  final int? timeSpentMs;

  Map<String, Object?> toJson() => _$CheckAttemptAnswerRequestToJson(this);
}
