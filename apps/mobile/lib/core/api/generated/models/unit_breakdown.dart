// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lesson_accuracy.dart';

part 'unit_breakdown.g.dart';

@JsonSerializable()
class UnitBreakdown {
  const UnitBreakdown({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.unitId,
    required this.unitNameAr,
    required this.lessons,
  });

  factory UnitBreakdown.fromJson(Map<String, Object?> json) => _$UnitBreakdownFromJson(json);

  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final String unitId;
  final String unitNameAr;
  final List<LessonAccuracy> lessons;

  Map<String, Object?> toJson() => _$UnitBreakdownToJson(this);
}
