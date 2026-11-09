// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_attempt_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitAttemptRequest _$SubmitAttemptRequestFromJson(
  Map<String, dynamic> json,
) => SubmitAttemptRequest(
  answers: (json['answers'] as List<dynamic>)
      .map((e) => SubmitAnswer.fromJson(e as Map<String, dynamic>))
      .toList(),
  timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
);

Map<String, dynamic> _$SubmitAttemptRequestToJson(
  SubmitAttemptRequest instance,
) => <String, dynamic>{
  'answers': instance.answers,
  'timeSpentMs': ?instance.timeSpentMs,
};
