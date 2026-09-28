// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'accuracy.dart';
import 'lesson_accuracy.dart';
import 'subject_accuracy.dart';
import 'type_accuracy.dart';
import 'unit_breakdown.dart';

part 'subject_stats.g.dart';

@JsonSerializable()
class SubjectStats {
  const SubjectStats({
    required this.subjectId,
    required this.subjectNameAr,
    required this.totals,
    required this.units,
    required this.lessons,
    required this.tracks,
    required this.byType,
  });

  factory SubjectStats.fromJson(Map<String, Object?> json) => _$SubjectStatsFromJson(json);

  final String subjectId;
  final String subjectNameAr;
  final Accuracy totals;
  final List<UnitBreakdown> units;
  final List<LessonAccuracy> lessons;
  final List<SubjectAccuracy> tracks;
  final List<TypeAccuracy> byType;

  Map<String, Object?> toJson() => _$SubjectStatsToJson(this);
}
