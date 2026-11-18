// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'card_image.dart';
import 'practice_diagram_label.dart';

part 'practice_diagram.g.dart';

@JsonSerializable()
class PracticeDiagram {
  const PracticeDiagram({
    required this.id,
    required this.subjectId,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.image,
    required this.labels,
    required this.contentVersion,
  });
  
  factory PracticeDiagram.fromJson(Map<String, Object?> json) => _$PracticeDiagramFromJson(json);
  
  final String id;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String titleAr;
  final CardImage image;
  final List<PracticeDiagramLabel> labels;
  final int contentVersion;

  Map<String, Object?> toJson() => _$PracticeDiagramToJson(this);
}
