// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'review_log_rating.dart';
import 'srs_state.dart';

part 'review_log.g.dart';

@JsonSerializable()
class ReviewLog {
  const ReviewLog({
    required this.id,
    required this.rating,
    required this.stateBefore,
    required this.stateAfter,
    required this.reviewedAt,
    this.flashcardId,
    this.userCardId,
    this.durationMs,
    this.undone,
  });

  factory ReviewLog.fromJson(Map<String, Object?> json) => _$ReviewLogFromJson(json);

  final String id;
  @JsonKey(includeIfNull: false)
  final String? flashcardId;
  @JsonKey(includeIfNull: false)
  final String? userCardId;
  final ReviewLogRating rating;
  final SrsState stateBefore;
  final SrsState stateAfter;
  final DateTime reviewedAt;
  @JsonKey(includeIfNull: false)
  final int? durationMs;
  @JsonKey(includeIfNull: false)
  final bool? undone;

  Map<String, Object?> toJson() => _$ReviewLogToJson(this);
}
