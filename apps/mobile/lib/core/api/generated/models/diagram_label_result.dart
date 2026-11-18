// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'diagram_label_result.g.dart';

@JsonSerializable()
class DiagramLabelResult {
  const DiagramLabelResult({
    required this.labelId,
    required this.number,
    required this.answer,
    required this.isCorrect,
    required this.acceptedAnswers,
  });
  
  factory DiagramLabelResult.fromJson(Map<String, Object?> json) => _$DiagramLabelResultFromJson(json);
  
  final String labelId;
  final int number;
  @JsonKey(includeIfNull: true)
  final String? answer;
  final bool isCorrect;
  final List<String> acceptedAnswers;

  Map<String, Object?> toJson() => _$DiagramLabelResultToJson(this);
}
