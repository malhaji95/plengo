// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_sync_state_state.dart';

part 'srs_sync_state.g.dart';

@JsonSerializable()
class SrsSyncState {
  const SrsSyncState({
    required this.state,
    required this.step,
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.lastReviewedAt,
    required this.flashcardId,
  });

  factory SrsSyncState.fromJson(Map<String, Object?> json) => _$SrsSyncStateFromJson(json);

  final SrsSyncStateState state;
  final int step;
  final DateTime dueAt;
  final int intervalDays;
  final num ease;
  final int reps;
  final int lapses;
  @JsonKey(includeIfNull: true)
  final DateTime? lastReviewedAt;
  final String flashcardId;

  Map<String, Object?> toJson() => _$SrsSyncStateToJson(this);
}
