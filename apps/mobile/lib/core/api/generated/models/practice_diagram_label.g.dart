// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_diagram_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeDiagramLabel _$PracticeDiagramLabelFromJson(
  Map<String, dynamic> json,
) => PracticeDiagramLabel(
  id: json['id'] as String,
  number: (json['number'] as num).toInt(),
  x: json['x'] as num?,
  y: json['y'] as num?,
);

Map<String, dynamic> _$PracticeDiagramLabelToJson(
  PracticeDiagramLabel instance,
) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'x': instance.x,
  'y': instance.y,
};
