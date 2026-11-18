// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'practice_diagram.dart';

part 'diagram_practice.g.dart';

@JsonSerializable()
class DiagramPractice {
  const DiagramPractice({
    required this.diagrams,
    required this.availableCount,
    required this.lockedCount,
    required this.urlsExpireAt,
  });
  
  factory DiagramPractice.fromJson(Map<String, Object?> json) => _$DiagramPracticeFromJson(json);
  
  final List<PracticeDiagram> diagrams;
  final int availableCount;
  final int lockedCount;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$DiagramPracticeToJson(this);
}
