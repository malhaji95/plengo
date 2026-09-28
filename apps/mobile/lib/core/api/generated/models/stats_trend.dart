// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trend_week.dart';

part 'stats_trend.g.dart';

@JsonSerializable()
class StatsTrend {
  const StatsTrend({
    required this.weeks,
  });
  
  factory StatsTrend.fromJson(Map<String, Object?> json) => _$StatsTrendFromJson(json);
  
  final List<TrendWeek> weeks;

  Map<String, Object?> toJson() => _$StatsTrendToJson(this);
}
