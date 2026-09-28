// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'type_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TypeAccuracy _$TypeAccuracyFromJson(Map<String, dynamic> json) => TypeAccuracy(
  answered: (json['answered'] as num).toInt(),
  correct: (json['correct'] as num).toInt(),
  accuracyPercent: (json['accuracyPercent'] as num?)?.toInt(),
  type: $enumDecode(_$TypeAccuracyTypeEnumMap, json['type']),
);

Map<String, dynamic> _$TypeAccuracyToJson(TypeAccuracy instance) =>
    <String, dynamic>{
      'answered': instance.answered,
      'correct': instance.correct,
      'accuracyPercent': instance.accuracyPercent,
      'type': instance.type,
    };

const _$TypeAccuracyTypeEnumMap = {
  TypeAccuracyType.mcq: 'mcq',
  TypeAccuracyType.trueFalse: 'true_false',
  TypeAccuracyType.written: 'written',
};
