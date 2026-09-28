// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_sync_outcome_status.dart';

part 'offline_sync_outcome.g.dart';

@JsonSerializable()
class OfflineSyncOutcome {
  const OfflineSyncOutcome({
    required this.clientAttemptId,
    required this.status,
    required this.reason,
    required this.attemptId,
    required this.correctCount,
    required this.totalCount,
    required this.mismatches,
  });
  
  factory OfflineSyncOutcome.fromJson(Map<String, Object?> json) => _$OfflineSyncOutcomeFromJson(json);
  
  final String clientAttemptId;
  final OfflineSyncOutcomeStatus status;
  @JsonKey(includeIfNull: true)
  final String? reason;
  @JsonKey(includeIfNull: true)
  final String? attemptId;
  @JsonKey(includeIfNull: true)
  final int? correctCount;
  @JsonKey(includeIfNull: true)
  final int? totalCount;
  final int mismatches;

  Map<String, Object?> toJson() => _$OfflineSyncOutcomeToJson(this);
}
