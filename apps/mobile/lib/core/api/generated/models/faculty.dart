// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'faculty.g.dart';

@JsonSerializable()
class Faculty {
  const Faculty({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.sortOrder,
    required this.isActive,
    required this.universityId,
  });
  
  factory Faculty.fromJson(Map<String, Object?> json) => _$FacultyFromJson(json);
  
  final String id;
  final String code;
  final String nameAr;
  final num sortOrder;
  final bool isActive;
  final String universityId;

  Map<String, Object?> toJson() => _$FacultyToJson(this);
}
