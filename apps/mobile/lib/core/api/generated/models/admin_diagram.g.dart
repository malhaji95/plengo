// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_diagram.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminDiagram _$AdminDiagramFromJson(Map<String, dynamic> json) => AdminDiagram(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  trackTitleAr: json['trackTitleAr'] as String?,
  unitId: json['unitId'] as String?,
  lessonId: json['lessonId'] as String?,
  titleAr: json['titleAr'] as String,
  description: json['description'] as String?,
  imageMediaId: json['imageMediaId'] as String,
  image: json['image'] == null
      ? null
      : CardImage.fromJson(json['image'] as Map<String, dynamic>),
  isFree: json['isFree'] as bool,
  freeSource: $enumDecode(_$AdminDiagramFreeSourceEnumMap, json['freeSource']),
  status: $enumDecode(_$AdminDiagramStatusEnumMap, json['status']),
  sortOrder: (json['sortOrder'] as num).toInt(),
  contentVersion: (json['contentVersion'] as num).toInt(),
  labels: (json['labels'] as List<dynamic>)
      .map((e) => AdminDiagramLabel.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$AdminDiagramToJson(AdminDiagram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
      'teacherTrackId': instance.teacherTrackId,
      'trackTitleAr': instance.trackTitleAr,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'imageMediaId': instance.imageMediaId,
      'image': instance.image,
      'isFree': instance.isFree,
      'freeSource': instance.freeSource,
      'status': instance.status,
      'sortOrder': instance.sortOrder,
      'contentVersion': instance.contentVersion,
      'labels': instance.labels,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$AdminDiagramFreeSourceEnumMap = {
  AdminDiagramFreeSource.rule: 'rule',
  AdminDiagramFreeSource.manualOverride: 'manual_override',
};

const _$AdminDiagramStatusEnumMap = {
  AdminDiagramStatus.draft: 'draft',
  AdminDiagramStatus.published: 'published',
  AdminDiagramStatus.archived: 'archived',
};
