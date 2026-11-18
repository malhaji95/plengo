// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'diagram_practice_request.g.dart';

@JsonSerializable()
class DiagramPracticeRequest {
  const DiagramPracticeRequest({
    required this.subjectId,
    required this.count,
    this.teacherTrackId,
    this.unitId,
    this.lessonIds,
  });
  
  factory DiagramPracticeRequest.fromJson(Map<String, Object?> json) => _$DiagramPracticeRequestFromJson(json);
  
  final String subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: false)
  final String? unitId;
  @JsonKey(includeIfNull: false)
  final List<String>? lessonIds;
  final int count;

  Map<String, Object?> toJson() => _$DiagramPracticeRequestToJson(this);
}
