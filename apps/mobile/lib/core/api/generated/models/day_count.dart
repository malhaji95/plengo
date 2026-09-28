// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'day_count.g.dart';

@JsonSerializable()
class DayCount {
  const DayCount({
    required this.date,
    required this.count,
  });
  
  factory DayCount.fromJson(Map<String, Object?> json) => _$DayCountFromJson(json);
  
  final String date;
  final int count;

  Map<String, Object?> toJson() => _$DayCountToJson(this);
}
