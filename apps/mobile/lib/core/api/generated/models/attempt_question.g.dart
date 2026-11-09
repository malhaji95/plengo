// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptQuestion _$AttemptQuestionFromJson(Map<String, dynamic> json) =>
    AttemptQuestion(
      questionId: json['questionId'] as String,
      type: $enumDecode(_$AttemptQuestionTypeEnumMap, json['type']),
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      questionText: json['questionText'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => AttemptOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedOptionId: json['selectedOptionId'] as String?,
      writtenAnswer: json['writtenAnswer'] as String?,
      flagged: json['flagged'] as bool,
      answeredAt: json['answeredAt'] as String?,
      timeSpentMs: (json['timeSpentMs'] as num?)?.toInt(),
      result: json['result'] == null
          ? null
          : CheckResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttemptQuestionToJson(AttemptQuestion instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'type': instance.type,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'questionText': instance.questionText,
      'options': instance.options,
      'selectedOptionId': instance.selectedOptionId,
      'writtenAnswer': instance.writtenAnswer,
      'flagged': instance.flagged,
      'answeredAt': instance.answeredAt,
      'timeSpentMs': instance.timeSpentMs,
      'result': instance.result,
    };

const _$AttemptQuestionTypeEnumMap = {
  AttemptQuestionType.mcq: 'mcq',
  AttemptQuestionType.trueFalse: 'true_false',
  AttemptQuestionType.written: 'written',
};
