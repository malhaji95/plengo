// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => UpdateProfileRequest(
  fullName: json['fullName'] as String?,
  educationLevelId: json['educationLevelId'] as String?,
  universityId: json['universityId'] as String?,
  facultyId: json['facultyId'] as String?,
  academicYearId: json['academicYearId'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  UpdateProfileRequest instance,
) => <String, dynamic>{
  'fullName': ?instance.fullName,
  'educationLevelId': ?instance.educationLevelId,
  'universityId': ?instance.universityId,
  'facultyId': ?instance.facultyId,
  'academicYearId': ?instance.academicYearId,
};
