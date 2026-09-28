// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'by_state.dart';
import 'day_count.dart';

part 'flashcard_stats.g.dart';

@JsonSerializable()
class FlashcardStats {
  const FlashcardStats({
    required this.dueToday,
    required this.forecast,
    required this.reviewsPerDay,
    required this.retentionPercent,
    required this.byState,
  });

  factory FlashcardStats.fromJson(Map<String, Object?> json) => _$FlashcardStatsFromJson(json);

  final int dueToday;
  final List<DayCount> forecast;
  final List<DayCount> reviewsPerDay;
  @JsonKey(includeIfNull: true)
  final int? retentionPercent;
  final ByState byState;

  Map<String, Object?> toJson() => _$FlashcardStatsToJson(this);
}
