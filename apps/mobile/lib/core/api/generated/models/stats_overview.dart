// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'accuracy.dart';
import 'missed_question.dart';
import 'mistakes.dart';
import 'subject_accuracy.dart';
import 'type_accuracy.dart';
import 'unit_accuracy.dart';

part 'stats_overview.g.dart';

@JsonSerializable()
class StatsOverview {
  const StatsOverview({
    required this.totals,
    required this.quizzesCompleted,
    required this.studyDays,
    required this.currentStreak,
    required this.averageTimeMs,
    required this.mistakes,
    required this.subjects,
    required this.byType,
    required this.weakestUnits,
    required this.mostMissed,
  });

  factory StatsOverview.fromJson(Map<String, Object?> json) => _$StatsOverviewFromJson(json);

  final Accuracy totals;
  final int quizzesCompleted;
  final int studyDays;
  final int currentStreak;
  @JsonKey(includeIfNull: true)
  final int? averageTimeMs;
  final Mistakes mistakes;
  final List<SubjectAccuracy> subjects;
  final List<TypeAccuracy> byType;
  final List<UnitAccuracy> weakestUnits;
  final List<MissedQuestion> mostMissed;

  Map<String, Object?> toJson() => _$StatsOverviewToJson(this);
}
