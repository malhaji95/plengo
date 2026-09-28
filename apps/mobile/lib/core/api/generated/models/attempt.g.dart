// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attempt _$AttemptFromJson(Map<String, dynamic> json) => Attempt(
  attempt: AttemptSummary.fromJson(json['attempt'] as Map<String, dynamic>),
  questions: (json['questions'] as List<dynamic>)
      .map((e) => AttemptQuestion.fromJson(e as Map<String, dynamic>))
      .toList(),
  serverTime: json['serverTime'] as String,
);

Map<String, dynamic> _$AttemptToJson(Attempt instance) => <String, dynamic>{
  'attempt': instance.attempt,
  'questions': instance.questions,
  'serverTime': instance.serverTime,
};
