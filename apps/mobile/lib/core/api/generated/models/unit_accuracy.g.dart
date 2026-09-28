// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitAccuracy _$UnitAccuracyFromJson(Map<String, dynamic> json) => UnitAccuracy(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
  unitId: json['unitId'] as String,
  unitNameAr: json['unitNameAr'] as String,
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
);

Map<String, dynamic> _$UnitAccuracyToJson(UnitAccuracy instance) =>
    <String, dynamic>{
      'answered': instance.answered,
      'correct': instance.correct,
      'accuracyPercent': instance.accuracyPercent,
      'unitId': instance.unitId,
      'unitNameAr': instance.unitNameAr,
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
    };
