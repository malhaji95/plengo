// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_stats_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlashcardStatsEnvelope _$FlashcardStatsEnvelopeFromJson(
  Map<String, dynamic> json,
) => FlashcardStatsEnvelope(
  success: json['success'] as bool,
  data: FlashcardStats.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$FlashcardStatsEnvelopeToJson(
  FlashcardStatsEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
