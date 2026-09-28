// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Accuracy _$AccuracyFromJson(Map<String, dynamic> json) => Accuracy(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
);

Map<String, dynamic> _$AccuracyToJson(Accuracy instance) => <String, dynamic>{
  'answered': instance.answered,
  'correct': instance.correct,
  'accuracyPercent': instance.accuracyPercent,
};
