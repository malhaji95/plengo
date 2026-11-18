// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_diagram.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeDiagram _$PracticeDiagramFromJson(Map<String, dynamic> json) =>
    PracticeDiagram(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      titleAr: json['titleAr'] as String,
      image: CardImage.fromJson(json['image'] as Map<String, dynamic>),
      labels: (json['labels'] as List<dynamic>)
          .map((e) => PracticeDiagramLabel.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentVersion: (json['contentVersion'] as num).toInt(),
    );

Map<String, dynamic> _$PracticeDiagramToJson(PracticeDiagram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'image': instance.image,
      'labels': instance.labels,
      'contentVersion': instance.contentVersion,
    };
