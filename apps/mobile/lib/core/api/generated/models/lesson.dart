// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lesson.g.dart';

@JsonSerializable()
class Lesson {
  const Lesson({
    required this.id,
    required this.subjectId,
    required this.unitId,
    required this.code,
    required this.titleAr,
    required this.sortOrder,
  });
  
  factory Lesson.fromJson(Map<String, Object?> json) => _$LessonFromJson(json);
  
  final String id;
  final String subjectId;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  final String code;
  final String titleAr;
  final num sortOrder;

  Map<String, Object?> toJson() => _$LessonToJson(this);
}
