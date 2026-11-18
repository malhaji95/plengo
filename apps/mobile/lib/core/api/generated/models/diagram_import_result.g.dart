// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_import_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramImportResult _$DiagramImportResultFromJson(Map<String, dynamic> json) =>
    DiagramImportResult(
      dryRun: json['dryRun'] as bool,
      totalRows: (json['totalRows'] as num).toInt(),
      diagrams: (json['diagrams'] as List<dynamic>)
          .map((e) => DiagramImportPreview.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiredImages: (json['requiredImages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      missingImages: (json['missingImages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      errors: (json['errors'] as List<dynamic>)
          .map((e) => ImportError.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdIds: (json['createdIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DiagramImportResultToJson(
  DiagramImportResult instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'totalRows': instance.totalRows,
  'diagrams': instance.diagrams,
  'requiredImages': instance.requiredImages,
  'missingImages': instance.missingImages,
  'errors': instance.errors,
  'createdIds': instance.createdIds,
};
