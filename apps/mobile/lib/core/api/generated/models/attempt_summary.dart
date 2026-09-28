// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_filters.dart';
import 'attempt_status.dart';
import 'attempt_summary_mode.dart';
import 'attempt_summary_source.dart';

part 'attempt_summary.g.dart';

@JsonSerializable()
class AttemptSummary {
  const AttemptSummary({
    required this.id,
    required this.clientAttemptId,
    required this.quizId,
    required this.source,
    required this.mode,
    required this.titleAr,
    required this.subjectId,
    required this.teacherTrackId,
    required this.filters,
    required this.status,
    required this.startedAt,
    required this.deadlineAt,
    required this.submittedAt,
    required this.submittedLate,
    required this.totalCount,
    required this.answeredCount,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.scorePercent,
    required this.passingScorePercent,
    required this.passed,
    required this.timeSpentMs,
  });

  factory AttemptSummary.fromJson(Map<String, Object?> json) => _$AttemptSummaryFromJson(json);

  final String id;
  final String clientAttemptId;
  @JsonKey(includeIfNull: true)
  final String? quizId;
  final AttemptSummarySource source;
  final AttemptSummaryMode mode;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final AttemptFilters? filters;
  final AttemptStatus status;
  final String startedAt;
  @JsonKey(includeIfNull: true)
  final String? deadlineAt;
  @JsonKey(includeIfNull: true)
  final String? submittedAt;
  final bool submittedLate;
  final int totalCount;
  final int answeredCount;
  @JsonKey(includeIfNull: true)
  final int? correctCount;
  @JsonKey(includeIfNull: true)
  final int? wrongCount;
  @JsonKey(includeIfNull: true)
  final int? skippedCount;
  @JsonKey(includeIfNull: true)
  final int? scorePercent;
  @JsonKey(includeIfNull: true)
  final int? passingScorePercent;
  @JsonKey(includeIfNull: true)
  final bool? passed;
  @JsonKey(includeIfNull: true)
  final int? timeSpentMs;

  Map<String, Object?> toJson() => _$AttemptSummaryToJson(this);
}
