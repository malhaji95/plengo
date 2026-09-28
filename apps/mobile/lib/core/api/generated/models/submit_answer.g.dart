// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitAnswer _$SubmitAnswerFromJson(Map<String, dynamic> json) => SubmitAnswer(
  questionId: json['questionId'] as String,
  selectedOptionId: json['selectedOptionId'] as String?,
  writtenAnswer: json['writtenAnswer'] as String?,
  timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
  flagged: json['flagged'] as bool?,
);

Map<String, dynamic> _$SubmitAnswerToJson(SubmitAnswer instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'selectedOptionId': ?instance.selectedOptionId,
  'writtenAnswer': ?instance.writtenAnswer,
  'timeSpentMs': ?instance.timeSpentMs,
  'flagged': ?instance.flagged,
};
