// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'unit_accuracy.g.dart';

@JsonSerializable()
class UnitAccuracy {
  const UnitAccuracy({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.unitId,
    required this.unitNameAr,
    required this.subjectId,
    required this.subjectNameAr,
  });

  factory UnitAccuracy.fromJson(Map<String, Object?> json) => _$UnitAccuracyFromJson(json);

  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final String unitId;
  final String unitNameAr;
  final String subjectId;
  final String subjectNameAr;

  Map<String, Object?> toJson() => _$UnitAccuracyToJson(this);
}
