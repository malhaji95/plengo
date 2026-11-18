// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_label.dart';

part 'create_diagram_request.g.dart';

@JsonSerializable()
class CreateDiagramRequest {
  const CreateDiagramRequest({
    required this.subjectId,
    required this.titleAr,
    required this.imageMediaId,
    required this.labels,
    this.teacherTrackId,
    this.unitId,
    this.lessonId,
    this.description,
    this.publish,
  });
  
  factory CreateDiagramRequest.fromJson(Map<String, Object?> json) => _$CreateDiagramRequestFromJson(json);
  
  final String subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: false)
  final String? unitId;
  @JsonKey(includeIfNull: false)
  final String? lessonId;
  final String titleAr;
  @JsonKey(includeIfNull: false)
  final String? description;
  final String imageMediaId;
  final List<DiagramLabel> labels;
  @JsonKey(includeIfNull: false)
  final bool? publish;

  Map<String, Object?> toJson() => _$CreateDiagramRequestToJson(this);
}
