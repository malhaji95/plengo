// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitBreakdown _$UnitBreakdownFromJson(Map<String, dynamic> json) => UnitBreakdown(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
  unitId: json['unitId'] as String,
  unitNameAr: json['unitNameAr'] as String,
  lessons: (json['lessons'] as List<dynamic>).map((e) => LessonAccuracy.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$UnitBreakdownToJson(UnitBreakdown instance) => <String, dynamic>{
  'answered': instance.answered,
  'correct': instance.correct,
  'accuracyPercent': instance.accuracyPercent,
  'unitId': instance.unitId,
  'unitNameAr': instance.unitNameAr,
  'lessons': instance.lessons,
};
