// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missed_question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissedQuestion _$MissedQuestionFromJson(Map<String, dynamic> json) => MissedQuestion(
  questionId: json['questionId'] as String,
  questionText: json['questionText'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  wrongCount: (json['wrongCount'] as num).toInt(),
);

Map<String, dynamic> _$MissedQuestionToJson(MissedQuestion instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'questionText': instance.questionText,
  'subjectNameAr': instance.subjectNameAr,
  'wrongCount': instance.wrongCount,
};
