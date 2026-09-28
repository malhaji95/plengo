// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offline_answer.g.dart';

@JsonSerializable()
class OfflineAnswer {
  const OfflineAnswer({
    required this.questionId,
    this.selectedOptionId,
    this.writtenAnswer,
    this.flagged,
    this.timeSpentMs,
    this.localIsCorrect,
  });

  factory OfflineAnswer.fromJson(Map<String, Object?> json) => _$OfflineAnswerFromJson(json);

  final String questionId;
  @JsonKey(includeIfNull: false)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: false)
  final String? writtenAnswer;
  @JsonKey(includeIfNull: false)
  final bool? flagged;
  @JsonKey(includeIfNull: false)
  final int? timeSpentMs;
  @JsonKey(includeIfNull: false)
  final bool? localIsCorrect;

  Map<String, Object?> toJson() => _$OfflineAnswerToJson(this);
}
