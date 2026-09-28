// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'academic_year.g.dart';

@JsonSerializable()
class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.sortOrder,
    required this.isActive,
    required this.facultyId,
  });

  factory AcademicYear.fromJson(Map<String, Object?> json) => _$AcademicYearFromJson(json);

  final String id;
  final String code;
  final String nameAr;
  final num sortOrder;
  final bool isActive;
  final String facultyId;

  Map<String, Object?> toJson() => _$AcademicYearToJson(this);
}
