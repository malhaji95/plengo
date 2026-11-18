// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_diagram_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateDiagramRequest _$CreateDiagramRequestFromJson(
  Map<String, dynamic> json,
) => CreateDiagramRequest(
  subjectId: json['subjectId'] as String,
  titleAr: json['titleAr'] as String,
  imageMediaId: json['imageMediaId'] as String,
  labels: (json['labels'] as List<dynamic>)
      .map((e) => DiagramLabel.fromJson(e as Map<String, dynamic>))
      .toList(),
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  description: json['description'] as String?,
  publish: json['publish'] as bool?,
);

Map<String, dynamic> _$CreateDiagramRequestToJson(
  CreateDiagramRequest instance,
) => <String, dynamic>{
  'subjectId': instance.subjectId,
  'teacherTrackId': ?instance.teacherTrackId,
  'unitId': ?instance.unitId,
  'lessonId': ?instance.lessonId,
  'titleAr': instance.titleAr,
  'description': ?instance.description,
  'imageMediaId': instance.imageMediaId,
  'labels': instance.labels,
  'publish': ?instance.publish,
};
