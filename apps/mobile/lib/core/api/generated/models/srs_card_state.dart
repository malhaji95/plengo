// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_card_state_state.dart';

part 'srs_card_state.g.dart';

@JsonSerializable()
class SrsCardState {
  const SrsCardState({
    required this.state,
    required this.step,
    required this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.lastReviewedAt,
    required this.flashcardId,
    required this.updatedAt,
  });
  
  factory SrsCardState.fromJson(Map<String, Object?> json) => _$SrsCardStateFromJson(json);
  
  final SrsCardStateState state;
  final int step;
  final DateTime dueAt;
  final int intervalDays;
  final num ease;
  final int reps;
  final int lapses;
  @JsonKey(includeIfNull: true)
  final DateTime? lastReviewedAt;
  final String flashcardId;
  final String updatedAt;

  Map<String, Object?> toJson() => _$SrsCardStateToJson(this);
}
