// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_attempt_answer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckAttemptAnswerRequest _$CheckAttemptAnswerRequestFromJson(
  Map<String, dynamic> json,
) => CheckAttemptAnswerRequest(
  selectedOptionId: json['selectedOptionId'] as String?,
  writtenAnswer: json['writtenAnswer'] as String?,
  timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
);

Map<String, dynamic> _$CheckAttemptAnswerRequestToJson(
  CheckAttemptAnswerRequest instance,
) => <String, dynamic>{
  'selectedOptionId': ?instance.selectedOptionId,
  'writtenAnswer': ?instance.writtenAnswer,
  'timeSpentMs': ?instance.timeSpentMs,
};
