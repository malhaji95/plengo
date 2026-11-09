// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlashcardStats _$FlashcardStatsFromJson(Map<String, dynamic> json) =>
    FlashcardStats(
      dueToday: (json['dueToday'] as num).toInt(),
      forecast: (json['forecast'] as List<dynamic>)
          .map((e) => DayCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviewsPerDay: (json['reviewsPerDay'] as List<dynamic>)
          .map((e) => DayCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      retentionPercent: (json['retentionPercent'] as num?)?.toInt(),
      byState: ByState.fromJson(json['byState'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FlashcardStatsToJson(FlashcardStats instance) =>
    <String, dynamic>{
      'dueToday': instance.dueToday,
      'forecast': instance.forecast,
      'reviewsPerDay': instance.reviewsPerDay,
      'retentionPercent': instance.retentionPercent,
      'byState': instance.byState,
    };
