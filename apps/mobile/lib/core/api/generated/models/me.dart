// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'me_role.dart';

part 'me.g.dart';

@JsonSerializable()
class Me {
  const Me({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.fullName,
    required this.educationLevelId,
    required this.universityId,
    required this.facultyId,
    required this.academicYearId,
  });
  
  factory Me.fromJson(Map<String, Object?> json) => _$MeFromJson(json);
  
  final String id;
  final String email;
  final bool emailVerified;
  final MeRole role;
  final String fullName;
  @JsonKey(includeIfNull: true)
  final String? educationLevelId;
  @JsonKey(includeIfNull: true)
  final String? universityId;
  @JsonKey(includeIfNull: true)
  final String? facultyId;
  @JsonKey(includeIfNull: true)
  final String? academicYearId;

  Map<String, Object?> toJson() => _$MeToJson(this);
}
