// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.educationLevelId,
    this.universityId,
    this.facultyId,
    this.academicYearId,
  });
  
  factory RegisterRequest.fromJson(Map<String, Object?> json) => _$RegisterRequestFromJson(json);
  
  final String fullName;
  final String email;
  final String password;
  @JsonKey(includeIfNull: false)
  final String? educationLevelId;
  @JsonKey(includeIfNull: false)
  final String? universityId;
  @JsonKey(includeIfNull: false)
  final String? facultyId;
  @JsonKey(includeIfNull: false)
  final String? academicYearId;

  Map<String, Object?> toJson() => _$RegisterRequestToJson(this);
}
