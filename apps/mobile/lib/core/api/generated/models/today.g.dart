// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Today _$TodayFromJson(Map<String, dynamic> json) => Today(
  dueCards: (json['dueCards'] as num).toInt(),
  goal: (json['goal'] as num).toInt(),
  done: (json['done'] as num).toInt(),
  goalMet: json['goalMet'] as bool,
  streak: (json['streak'] as num).toInt(),
);

Map<String, dynamic> _$TodayToJson(Today instance) => <String, dynamic>{
  'dueCards': instance.dueCards,
  'goal': instance.goal,
  'done': instance.done,
  'goalMet': instance.goalMet,
  'streak': instance.streak,
};
