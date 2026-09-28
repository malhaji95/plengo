// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_week.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrendWeek _$TrendWeekFromJson(Map<String, dynamic> json) => TrendWeek(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
  weekStart: json['weekStart'] as String,
);

Map<String, dynamic> _$TrendWeekToJson(TrendWeek instance) => <String, dynamic>{
  'answered': instance.answered,
  'correct': instance.correct,
  'accuracyPercent': instance.accuracyPercent,
  'weekStart': instance.weekStart,
};
