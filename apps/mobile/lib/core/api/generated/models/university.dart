// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'university.g.dart';

@JsonSerializable()
class University {
  const University({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.sortOrder,
    required this.isActive,
  });
  
  factory University.fromJson(Map<String, Object?> json) => _$UniversityFromJson(json);
  
  final String id;
  final String code;
  final String nameAr;
  final num sortOrder;
  final bool isActive;

  Map<String, Object?> toJson() => _$UniversityToJson(this);
}
