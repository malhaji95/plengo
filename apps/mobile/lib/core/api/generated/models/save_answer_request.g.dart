// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_answer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveAnswerRequest _$SaveAnswerRequestFromJson(Map<String, dynamic> json) => SaveAnswerRequest(
  selectedOptionId: json['selectedOptionId'] as String?,
  writtenAnswer: json['writtenAnswer'] as String?,
  timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
  flagged: json['flagged'] as bool?,
);

Map<String, dynamic> _$SaveAnswerRequestToJson(SaveAnswerRequest instance) => <String, dynamic>{
  'selectedOptionId': ?instance.selectedOptionId,
  'writtenAnswer': ?instance.writtenAnswer,
  'timeSpentMs': ?instance.timeSpentMs,
  'flagged': ?instance.flagged,
};
