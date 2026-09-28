// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'flashcard_stats.dart';

part 'flashcard_stats_envelope.g.dart';

@JsonSerializable()
class FlashcardStatsEnvelope {
  const FlashcardStatsEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory FlashcardStatsEnvelope.fromJson(Map<String, Object?> json) => _$FlashcardStatsEnvelopeFromJson(json);
  
  final bool success;
  final FlashcardStats data;
  final dynamic error;

  Map<String, Object?> toJson() => _$FlashcardStatsEnvelopeToJson(this);
}
