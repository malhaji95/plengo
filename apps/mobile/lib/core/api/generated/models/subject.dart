// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'subject.g.dart';

@JsonSerializable()
class Subject {
  const Subject({
    required this.id,
    required this.educationLevelId,
    required this.universityId,
    required this.facultyId,
    required this.academicYearId,
    required this.code,
    required this.nameAr,
    required this.description,
    required this.coverMediaId,
    required this.coverUrl,
    required this.sortOrder,
    required this.isActive,
  });
  
  factory Subject.fromJson(Map<String, Object?> json) => _$SubjectFromJson(json);
  
  final String id;
  final String educationLevelId;
  @JsonKey(includeIfNull: true)
  final String? universityId;
  @JsonKey(includeIfNull: true)
  final String? facultyId;
  @JsonKey(includeIfNull: true)
  final String? academicYearId;
  final String code;
  final String nameAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  @JsonKey(includeIfNull: true)
  final String? coverMediaId;
  @JsonKey(includeIfNull: true)
  final String? coverUrl;
  final num sortOrder;
  final bool isActive;

  Map<String, Object?> toJson() => _$SubjectToJson(this);
}
