// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'diagram_label.g.dart';

@JsonSerializable()
class DiagramLabel {
  const DiagramLabel({
    required this.number,
    required this.answers,
    this.x,
    this.y,
  });
  
  factory DiagramLabel.fromJson(Map<String, Object?> json) => _$DiagramLabelFromJson(json);
  
  final int number;
  @JsonKey(includeIfNull: false)
  final num? x;
  @JsonKey(includeIfNull: false)
  final num? y;
  final List<String> answers;

  Map<String, Object?> toJson() => _$DiagramLabelToJson(this);
}
