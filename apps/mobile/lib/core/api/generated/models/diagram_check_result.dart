// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_label_result.dart';

part 'diagram_check_result.g.dart';

@JsonSerializable()
class DiagramCheckResult {
  const DiagramCheckResult({
    required this.diagramId,
    required this.correctCount,
    required this.totalCount,
    required this.labels,
  });
  
  factory DiagramCheckResult.fromJson(Map<String, Object?> json) => _$DiagramCheckResultFromJson(json);
  
  final String diagramId;
  final int correctCount;
  final int totalCount;
  final List<DiagramLabelResult> labels;

  Map<String, Object?> toJson() => _$DiagramCheckResultToJson(this);
}
