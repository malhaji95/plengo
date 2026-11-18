// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_diagram_free_source.dart';
import 'admin_diagram_label.dart';
import 'admin_diagram_status.dart';
import 'card_image.dart';

part 'admin_diagram.g.dart';

@JsonSerializable()
class AdminDiagram {
  const AdminDiagram({
    required this.id,
    required this.subjectId,
    required this.subjectNameAr,
    required this.teacherTrackId,
    required this.trackTitleAr,
    required this.unitId,
    required this.lessonId,
    required this.titleAr,
    required this.description,
    required this.imageMediaId,
    required this.image,
    required this.isFree,
    required this.freeSource,
    required this.status,
    required this.sortOrder,
    required this.contentVersion,
    required this.labels,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AdminDiagram.fromJson(Map<String, Object?> json) => _$AdminDiagramFromJson(json);
  
  final String id;
  final String subjectId;
  final String subjectNameAr;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: true)
  final String? trackTitleAr;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? lessonId;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  final String imageMediaId;
  @JsonKey(includeIfNull: true)
  final CardImage? image;
  final bool isFree;
  final AdminDiagramFreeSource freeSource;
  final AdminDiagramStatus status;
  final int sortOrder;
  final int contentVersion;
  final List<AdminDiagramLabel> labels;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$AdminDiagramToJson(this);
}
