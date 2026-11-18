// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_label.dart';

part 'update_diagram_request.g.dart';

@JsonSerializable()
class UpdateDiagramRequest {
  const UpdateDiagramRequest({
    this.unitId,
    this.lessonId,
    this.titleAr,
    this.description,
    this.imageMediaId,
    this.labels,
  });
  
  factory UpdateDiagramRequest.fromJson(Map<String, Object?> json) => _$UpdateDiagramRequestFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final String? unitId;
  @JsonKey(includeIfNull: false)
  final String? lessonId;
  @JsonKey(includeIfNull: false)
  final String? titleAr;
  @JsonKey(includeIfNull: false)
  final String? description;
  @JsonKey(includeIfNull: false)
  final String? imageMediaId;
  @JsonKey(includeIfNull: false)
  final List<DiagramLabel>? labels;

  Map<String, Object?> toJson() => _$UpdateDiagramRequestToJson(this);
}
