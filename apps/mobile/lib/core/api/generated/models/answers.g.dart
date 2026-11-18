// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Answers _$AnswersFromJson(Map<String, dynamic> json) => Answers(
  number: (json['number'] as num).toInt(),
  answer: json['answer'] as String,
);

Map<String, dynamic> _$AnswersToJson(Answers instance) => <String, dynamic>{
  'number': instance.number,
  'answer': instance.answer,
};
