// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramLabel _$DiagramLabelFromJson(Map<String, dynamic> json) => DiagramLabel(
  number: (json['number'] as num).toInt(),
  answers: (json['answers'] as List<dynamic>).map((e) => e as String).toList(),
  x: json['x'] as num?,
  y: json['y'] as num?,
);

Map<String, dynamic> _$DiagramLabelToJson(DiagramLabel instance) =>
    <String, dynamic>{
      'number': instance.number,
      'x': ?instance.x,
      'y': ?instance.y,
      'answers': instance.answers,
    };
