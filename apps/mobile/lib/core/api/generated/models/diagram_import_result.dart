// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_import_preview.dart';
import 'import_error.dart';

part 'diagram_import_result.g.dart';

@JsonSerializable()
class DiagramImportResult {
  const DiagramImportResult({
    required this.dryRun,
    required this.totalRows,
    required this.diagrams,
    required this.requiredImages,
    required this.missingImages,
    required this.errors,
    required this.createdIds,
  });
  
  factory DiagramImportResult.fromJson(Map<String, Object?> json) => _$DiagramImportResultFromJson(json);
  
  final bool dryRun;
  final int totalRows;
  final List<DiagramImportPreview> diagrams;
  final List<String> requiredImages;
  final List<String> missingImages;
  final List<ImportError> errors;
  final List<String> createdIds;

  Map<String, Object?> toJson() => _$DiagramImportResultToJson(this);
}
