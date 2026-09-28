// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'trend_week.g.dart';

@JsonSerializable()
class TrendWeek {
  const TrendWeek({
    required this.answered,
    required this.correct,
    required this.accuracyPercent,
    required this.weekStart,
  });
  
  factory TrendWeek.fromJson(Map<String, Object?> json) => _$TrendWeekFromJson(json);
  
  final int answered;
  final int correct;
  @JsonKey(includeIfNull: true)
  final int? accuracyPercent;
  final String weekStart;

  Map<String, Object?> toJson() => _$TrendWeekToJson(this);
}
