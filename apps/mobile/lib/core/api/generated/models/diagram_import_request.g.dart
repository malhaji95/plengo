// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramImportRequest _$DiagramImportRequestFromJson(
  Map<String, dynamic> json,
) => DiagramImportRequest(
  format: $enumDecode(_$ImportFormatEnumMap, json['format']),
  fileName: json['fileName'] as String,
  contentBase64: json['contentBase64'] as String,
  dryRun: json['dryRun'] as bool,
  images: (json['images'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  publish: json['publish'] as bool?,
);

Map<String, dynamic> _$DiagramImportRequestToJson(
  DiagramImportRequest instance,
) => <String, dynamic>{
  'format': instance.format,
  'fileName': instance.fileName,
  'contentBase64': instance.contentBase64,
  'images': ?instance.images,
  'dryRun': instance.dryRun,
  'publish': ?instance.publish,
};

const _$ImportFormatEnumMap = {
  ImportFormat.csv: 'csv',
  ImportFormat.xlsx: 'xlsx',
};
