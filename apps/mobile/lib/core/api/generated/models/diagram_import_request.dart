// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'import_format.dart';

part 'diagram_import_request.g.dart';

@JsonSerializable()
class DiagramImportRequest {
  const DiagramImportRequest({
    required this.format,
    required this.fileName,
    required this.contentBase64,
    required this.dryRun,
    this.images,
    this.publish,
  });
  
  factory DiagramImportRequest.fromJson(Map<String, Object?> json) => _$DiagramImportRequestFromJson(json);
  
  final ImportFormat format;
  final String fileName;
  final String contentBase64;
  @JsonKey(includeIfNull: false)
  final Map<String, String>? images;
  final bool dryRun;
  @JsonKey(includeIfNull: false)
  final bool? publish;

  Map<String, Object?> toJson() => _$DiagramImportRequestToJson(this);
}
