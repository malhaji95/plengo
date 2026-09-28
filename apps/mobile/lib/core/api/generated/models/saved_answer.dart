// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'saved_answer.g.dart';

@JsonSerializable()
class SavedAnswer {
  const SavedAnswer({
    required this.questionId,
    required this.selectedOptionId,
    required this.writtenAnswer,
    required this.flagged,
    required this.answeredAt,
  });

  factory SavedAnswer.fromJson(Map<String, Object?> json) => _$SavedAnswerFromJson(json);

  final String questionId;
  @JsonKey(includeIfNull: true)
  final String? selectedOptionId;
  @JsonKey(includeIfNull: true)
  final String? writtenAnswer;
  final bool flagged;
  @JsonKey(includeIfNull: true)
  final String? answeredAt;

  Map<String, Object?> toJson() => _$SavedAnswerToJson(this);
}
