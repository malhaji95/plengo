// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_answer_request.g.dart';

@JsonSerializable()
class SaveAnswerRequest {
  const SaveAnswerRequest({this.selectedOptionId, this.writtenAnswer, this.timeSpentMs, this.flagged});

  factory SaveAnswerRequest.fromJson(Map<String, Object?> json) => _$SaveAnswerRequestFromJson(json);

  @JsonKey(includeIfNull: false)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: false)
  final String? writtenAnswer;
  @JsonKey(includeIfNull: false)
  final int? timeSpentMs;
  @JsonKey(includeIfNull: false)
  final bool? flagged;

  Map<String, Object?> toJson() => _$SaveAnswerRequestToJson(this);
}
