// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_label_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramLabelResult _$DiagramLabelResultFromJson(Map<String, dynamic> json) =>
    DiagramLabelResult(
      labelId: json['labelId'] as String,
      number: (json['number'] as num).toInt(),
      answer: json['answer'] as String?,
      isCorrect: json['isCorrect'] as bool,
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DiagramLabelResultToJson(DiagramLabelResult instance) =>
    <String, dynamic>{
      'labelId': instance.labelId,
      'number': instance.number,
      'answer': instance.answer,
      'isCorrect': instance.isCorrect,
      'acceptedAnswers': instance.acceptedAnswers,
    };
