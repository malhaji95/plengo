// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatsOverview _$StatsOverviewFromJson(Map<String, dynamic> json) => StatsOverview(
  totals: Accuracy.fromJson(json['totals'] as Map<String, dynamic>),
  quizzesCompleted: (json['quizzesCompleted'] as num).toInt(),
  studyDays: (json['studyDays'] as num).toInt(),
  currentStreak: (json['currentStreak'] as num).toInt(),
  averageTimeMs: (json['averageTimeMs'] as num?)?.toInt(),
  mistakes: Mistakes.fromJson(json['mistakes'] as Map<String, dynamic>),
  subjects: (json['subjects'] as List<dynamic>)
      .map((e) => SubjectAccuracy.fromJson(e as Map<String, dynamic>))
      .toList(),
  byType: (json['byType'] as List<dynamic>).map((e) => TypeAccuracy.fromJson(e as Map<String, dynamic>)).toList(),
  weakestUnits: (json['weakestUnits'] as List<dynamic>)
      .map((e) => UnitAccuracy.fromJson(e as Map<String, dynamic>))
      .toList(),
  mostMissed: (json['mostMissed'] as List<dynamic>)
      .map((e) => MissedQuestion.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StatsOverviewToJson(StatsOverview instance) => <String, dynamic>{
  'totals': instance.totals,
  'quizzesCompleted': instance.quizzesCompleted,
  'studyDays': instance.studyDays,
  'currentStreak': instance.currentStreak,
  'averageTimeMs': instance.averageTimeMs,
  'mistakes': instance.mistakes,
  'subjects': instance.subjects,
  'byType': instance.byType,
  'weakestUnits': instance.weakestUnits,
  'mostMissed': instance.mostMissed,
};
