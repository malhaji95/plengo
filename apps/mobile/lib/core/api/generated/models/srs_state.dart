// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_state_state.dart';

part 'srs_state.g.dart';

@JsonSerializable()
class SrsState {
  const SrsState({
    required this.state,
    required this.step,
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.lastReviewedAt,
  });
  
  factory SrsState.fromJson(Map<String, Object?> json) => _$SrsStateFromJson(json);
  
  final SrsStateState state;
  final int step;
  final DateTime dueAt;
  final int intervalDays;
  final num ease;
  final int reps;
  final int lapses;
  @JsonKey(includeIfNull: true)
  final DateTime? lastReviewedAt;

  Map<String, Object?> toJson() => _$SrsStateToJson(this);
}
