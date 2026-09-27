// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'education_level.g.dart';

@JsonSerializable()
class EducationLevel {
  const EducationLevel({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.sortOrder,
    required this.isCollege,
  });
  
  factory EducationLevel.fromJson(Map<String, Object?> json) => _$EducationLevelFromJson(json);
  
  final String id;
  final String code;
  final String nameAr;
  final num sortOrder;
  final bool isCollege;

  Map<String, Object?> toJson() => _$EducationLevelToJson(this);
}
