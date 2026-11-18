// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_answer_correct_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarkAnswerCorrectResult _$MarkAnswerCorrectResultFromJson(
  Map<String, dynamic> json,
) => MarkAnswerCorrectResult(
  questionId: json['questionId'] as String,
  result: CheckResult.fromJson(json['result'] as Map<String, dynamic>),
  attempt: AttemptSummary.fromJson(json['attempt'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MarkAnswerCorrectResultToJson(
  MarkAnswerCorrectResult instance,
) => <String, dynamic>{
  'questionId': instance.questionId,
  'result': instance.result,
  'attempt': instance.attempt,
};
