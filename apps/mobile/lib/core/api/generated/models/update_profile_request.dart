// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

@JsonSerializable()
class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.educationLevelId,
    this.universityId,
    this.facultyId,
    this.academicYearId,
    this.avatarMediaId,
  });

  factory UpdateProfileRequest.fromJson(Map<String, Object?> json) => _$UpdateProfileRequestFromJson(json);

  @JsonKey(includeIfNull: false)
  final String? fullName;
  @JsonKey(includeIfNull: false)
  final String? educationLevelId;
  @JsonKey(includeIfNull: false)
  final String? universityId;
  @JsonKey(includeIfNull: false)
  final String? facultyId;
  @JsonKey(includeIfNull: false)
  final String? academicYearId;
  @JsonKey(includeIfNull: false)
  final String? avatarMediaId;

  Map<String, Object?> toJson() => _$UpdateProfileRequestToJson(this);
}
