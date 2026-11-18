// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'admin_diagram_label.g.dart';

@JsonSerializable()
class AdminDiagramLabel {
  const AdminDiagramLabel({
    required this.id,
    required this.number,
    required this.x,
    required this.y,
    required this.answers,
    required this.sortOrder,
  });
  
  factory AdminDiagramLabel.fromJson(Map<String, Object?> json) => _$AdminDiagramLabelFromJson(json);
  
  final String id;
  final int number;
  @JsonKey(includeIfNull: true)
  final num? x;
  @JsonKey(includeIfNull: true)
  final num? y;
  final List<String> answers;
  final int sortOrder;

  Map<String, Object?> toJson() => _$AdminDiagramLabelToJson(this);
}
