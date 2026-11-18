// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_diagram_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateDiagramRequest _$UpdateDiagramRequestFromJson(
  Map<String, dynamic> json,
) => UpdateDiagramRequest(
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String?,
  description: json['description'] as String?,
  imageMediaId: json['imageMediaId'] as String?,
  labels: (json['labels'] as List<dynamic>?)
      ?.map((e) => DiagramLabel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateDiagramRequestToJson(
  UpdateDiagramRequest instance,
) => <String, dynamic>{
  'unitId': ?instance.unitId,
  'lessonId': ?instance.lessonId,
  'titleAr': ?instance.titleAr,
  'description': ?instance.description,
  'imageMediaId': ?instance.imageMediaId,
  'labels': ?instance.labels,
};
