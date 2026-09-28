// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_answer.dart';
import 'offline_attempt_mode.dart';
import 'offline_attempt_source.dart';

part 'offline_attempt.g.dart';

@JsonSerializable()
class OfflineAttempt {
  const OfflineAttempt({
    required this.clientAttemptId,
    required this.source,
    required this.mode,
    required this.questionIds,
    required this.startedAt,
    required this.submittedAt,
    required this.answers,
    this.quizId,
    this.subjectId,
    this.teacherTrackId,
    this.timeSpentMs,
  });

  factory OfflineAttempt.fromJson(Map<String, Object?> json) => _$OfflineAttemptFromJson(json);

  final String clientAttemptId;
  final OfflineAttemptSource source;
  final OfflineAttemptMode mode;
  @JsonKey(includeIfNull: false)
  final String? quizId;
  @JsonKey(includeIfNull: false)
  final String? subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;
  final List<String> questionIds;
  final DateTime startedAt;
  final DateTime submittedAt;
  @JsonKey(includeIfNull: false)
  final int? timeSpentMs;
  final List<OfflineAnswer> answers;

  Map<String, Object?> toJson() => _$OfflineAttemptToJson(this);
}
