// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitProgress _$UnitProgressFromJson(Map<String, dynamic> json) => UnitProgress(
  questionsAttempted: (json['questionsAttempted'] as num).toInt(),
  questionsCorrect: (json['questionsCorrect'] as num).toInt(),
  questionsTotal: (json['questionsTotal'] as num).toInt(),
  quizzesCompleted: (json['quizzesCompleted'] as num).toInt(),
  quizzesTotal: (json['quizzesTotal'] as num).toInt(),
  flashcardsStudied: (json['flashcardsStudied'] as num).toInt(),
  flashcardsTotal: (json['flashcardsTotal'] as num).toInt(),
  completionPercent: (json['completionPercent'] as num).toInt(),
  unitId: json['unitId'] as String,
);

Map<String, dynamic> _$UnitProgressToJson(UnitProgress instance) => <String, dynamic>{
  'questionsAttempted': instance.questionsAttempted,
  'questionsCorrect': instance.questionsCorrect,
  'questionsTotal': instance.questionsTotal,
  'quizzesCompleted': instance.quizzesCompleted,
  'quizzesTotal': instance.quizzesTotal,
  'flashcardsStudied': instance.flashcardsStudied,
  'flashcardsTotal': instance.flashcardsTotal,
  'completionPercent': instance.completionPercent,
  'unitId': instance.unitId,
};
