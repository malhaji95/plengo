// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_filters_types.dart';

part 'attempt_filters.g.dart';

@JsonSerializable()
class AttemptFilters {
  const AttemptFilters({
    this.subjectId,
    this.teacherTrackId,
    this.unitId,
    this.lessonId,
    this.types,
    this.count,
    this.questionIds,
  });

  factory AttemptFilters.fromJson(Map<String, Object?> json) => _$AttemptFiltersFromJson(json);

  @JsonKey(includeIfNull: false)
  final String? subjectId;
  @JsonKey(includeIfNull: false)
  final String? teacherTrackId;
  @JsonKey(includeIfNull: false)
  final String? unitId;
  @JsonKey(includeIfNull: false)
  final String? lessonId;
  @JsonKey(includeIfNull: false)
  final List<AttemptFiltersTypes>? types;
  @JsonKey(includeIfNull: false)
  final int? count;
  @JsonKey(includeIfNull: false)
  final List<String>? questionIds;

  Map<String, Object?> toJson() => _$AttemptFiltersToJson(this);
}
