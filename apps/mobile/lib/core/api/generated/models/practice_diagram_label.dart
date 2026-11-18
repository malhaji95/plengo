// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'practice_diagram_label.g.dart';

@JsonSerializable()
class PracticeDiagramLabel {
  const PracticeDiagramLabel({
    required this.id,
    required this.number,
    required this.x,
    required this.y,
  });
  
  factory PracticeDiagramLabel.fromJson(Map<String, Object?> json) => _$PracticeDiagramLabelFromJson(json);
  
  final String id;
  final int number;
  @JsonKey(includeIfNull: true)
  final num? x;
  @JsonKey(includeIfNull: true)
  final num? y;

  Map<String, Object?> toJson() => _$PracticeDiagramLabelToJson(this);
}
