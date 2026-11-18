// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_diagram_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDiagramLabel _$AdminDiagramLabelFromJson(Map<String, dynamic> json) =>
    AdminDiagramLabel(
      id: json['id'] as String,
      number: (json['number'] as num).toInt(),
      x: json['x'] as num?,
      y: json['y'] as num?,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$AdminDiagramLabelToJson(AdminDiagramLabel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'x': instance.x,
      'y': instance.y,
      'answers': instance.answers,
      'sortOrder': instance.sortOrder,
    };
