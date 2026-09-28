// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'check_result.g.dart';

@JsonSerializable()
class CheckResult {
  const CheckResult({
    required this.isCorrect,
    required this.correctOptionId,
    required this.correctAnswer,
    required this.explanation,
  });

  factory CheckResult.fromJson(Map<String, Object?> json) => _$CheckResultFromJson(json);

  final bool isCorrect;
  @JsonKey(includeIfNull: true)
  final String? correctOptionId;
  @JsonKey(includeIfNull: true)
  final String? correctAnswer;
  @JsonKey(includeIfNull: true)
  final String? explanation;

  Map<String, Object?> toJson() => _$CheckResultToJson(this);
}
