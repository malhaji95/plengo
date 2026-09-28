// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lesson.dart';

part 'unit_with_lessons.g.dart';

@JsonSerializable()
class UnitWithLessons {
  const UnitWithLessons({
    required this.id,
    required this.subjectId,
    required this.code,
    required this.titleAr,
    required this.sortOrder,
    required this.lessons,
  });

  factory UnitWithLessons.fromJson(Map<String, Object?> json) => _$UnitWithLessonsFromJson(json);

  final String id;
  final String subjectId;
  final String code;
  final String titleAr;
  final num sortOrder;
  final List<Lesson> lessons;

  Map<String, Object?> toJson() => _$UnitWithLessonsToJson(this);
}
