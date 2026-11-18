// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_import_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramImportPreview _$DiagramImportPreviewFromJson(
  Map<String, dynamic> json,
) => DiagramImportPreview(
  ref: json['ref'] as String,
  titleAr: json['titleAr'] as String,
  subjectCode: json['subjectCode'] as String,
  unitCode: json['unitCode'] as String?,
  lessonCode: json['lessonCode'] as String?,
  teacherTrackCode: json['teacherTrackCode'] as String?,
  imageFile: json['imageFile'] as String,
  labels: (json['labels'] as List<dynamic>)
      .map((e) => Labels.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DiagramImportPreviewToJson(
  DiagramImportPreview instance,
) => <String, dynamic>{
  'ref': instance.ref,
  'titleAr': instance.titleAr,
  'subjectCode': instance.subjectCode,
  'unitCode': instance.unitCode,
  'lessonCode': instance.lessonCode,
  'teacherTrackCode': instance.teacherTrackCode,
  'imageFile': instance.imageFile,
  'labels': instance.labels,
};
