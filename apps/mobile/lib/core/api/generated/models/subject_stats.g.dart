// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectStats _$SubjectStatsFromJson(Map<String, dynamic> json) => SubjectStats(
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  totals: Accuracy.fromJson(json['totals'] as Map<String, dynamic>),
  units: (json['units'] as List<dynamic>).map((e) => UnitBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
  lessons: (json['lessons'] as List<dynamic>).map((e) => LessonAccuracy.fromJson(e as Map<String, dynamic>)).toList(),
  tracks: (json['tracks'] as List<dynamic>).map((e) => SubjectAccuracy.fromJson(e as Map<String, dynamic>)).toList(),
  byType: (json['byType'] as List<dynamic>).map((e) => TypeAccuracy.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$SubjectStatsToJson(SubjectStats instance) => <String, dynamic>{
  'subjectId': instance.subjectId,
  'subjectNameAr': instance.subjectNameAr,
  'totals': instance.totals,
  'units': instance.units,
  'lessons': instance.lessons,
  'tracks': instance.tracks,
  'byType': instance.byType,
};
