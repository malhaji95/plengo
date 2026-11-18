// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'labels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Labels _$LabelsFromJson(Map<String, dynamic> json) => Labels(
  number: (json['number'] as num).toInt(),
  answers: (json['answers'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$LabelsToJson(Labels instance) => <String, dynamic>{
  'number': instance.number,
  'answers': instance.answers,
};
