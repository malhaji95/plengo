// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'check_answer_request.g.dart';

@JsonSerializable()
class CheckAnswerRequest {
  const CheckAnswerRequest({
    this.selectedOptionId,
    this.writtenAnswer,
  });
  
  factory CheckAnswerRequest.fromJson(Map<String, Object?> json) => _$CheckAnswerRequestFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: false)
  final String? writtenAnswer;

  Map<String, Object?> toJson() => _$CheckAnswerRequestToJson(this);
}
