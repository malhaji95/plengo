// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineAnswer _$OfflineAnswerFromJson(Map<String, dynamic> json) =>
    OfflineAnswer(
      questionId: json['questionId'] as String,
      selectedOptionId: json['selectedOptionId'] as String?,
      writtenAnswer: json['writtenAnswer'] as String?,
      flagged: json['flagged'] as bool?,
      timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
      localIsCorrect: json['localIsCorrect'] as bool?,
    );

Map<String, dynamic> _$OfflineAnswerToJson(OfflineAnswer instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedOptionId': ?instance.selectedOptionId,
      'writtenAnswer': ?instance.writtenAnswer,
      'flagged': ?instance.flagged,
      'timeSpentMs': ?instance.timeSpentMs,
      'localIsCorrect': ?instance.localIsCorrect,
    };
