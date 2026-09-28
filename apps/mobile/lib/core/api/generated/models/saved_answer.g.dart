// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedAnswer _$SavedAnswerFromJson(Map<String, dynamic> json) => SavedAnswer(
  questionId: json['questionId'] as String,
  selectedOptionId: json['selectedOptionId'] as String?,
  writtenAnswer: json['writtenAnswer'] as String?,
  flagged: json['flagged'] as bool,
  answeredAt: json['answeredAt'] as String?,
);

Map<String, dynamic> _$SavedAnswerToJson(SavedAnswer instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'selectedOptionId': instance.selectedOptionId,
  'writtenAnswer': instance.writtenAnswer,
  'flagged': instance.flagged,
  'answeredAt': instance.answeredAt,
};
