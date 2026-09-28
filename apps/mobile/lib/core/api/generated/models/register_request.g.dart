// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) => RegisterRequest(
  fullName: json['fullName'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  educationLevelId: json['educationLevelId'] as String,
  universityId: json['universityId'] as String?,
  facultyId: json['facultyId'] as String?,
  academicYearId: json['academicYearId'] as String?,
);

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) => <String, dynamic>{
  'fullName': instance.fullName,
  'email': instance.email,
  'password': instance.password,
  'educationLevelId': instance.educationLevelId,
  'universityId': ?instance.universityId,
  'facultyId': ?instance.facultyId,
  'academicYearId': ?instance.academicYearId,
};
