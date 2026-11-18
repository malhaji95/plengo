// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'labels.dart';

part 'diagram_import_preview.g.dart';

@JsonSerializable()
class DiagramImportPreview {
  const DiagramImportPreview({
    required this.ref,
    required this.titleAr,
    required this.subjectCode,
    required this.unitCode,
    required this.lessonCode,
    required this.teacherTrackCode,
    required this.imageFile,
    required this.labels,
  });
  
  factory DiagramImportPreview.fromJson(Map<String, Object?> json) => _$DiagramImportPreviewFromJson(json);
  
  final String ref;
  final String titleAr;
  final String subjectCode;
  @JsonKey(includeIfNull: true)
  final String? unitCode;
  @JsonKey(includeIfNull: true)
  final String? lessonCode;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackCode;
  final String imageFile;
  final List<Labels> labels;

  Map<String, Object?> toJson() => _$DiagramImportPreviewToJson(this);
}
