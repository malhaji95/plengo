// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Me _$MeFromJson(Map<String, dynamic> json) => Me(
  id: json['id'] as String,
  email: json['email'] as String,
  emailVerified: json['emailVerified'] as bool,
  role: $enumDecode(_$MeRoleEnumMap, json['role']),
  fullName: json['fullName'] as String,
  educationLevelId: json['educationLevelId'] as String?,
  universityId: json['universityId'] as String?,
  facultyId: json['facultyId'] as String?,
  academicYearId: json['academicYearId'] as String?,
);

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'emailVerified': instance.emailVerified,
  'role': instance.role,
  'fullName': instance.fullName,
  'educationLevelId': instance.educationLevelId,
  'universityId': instance.universityId,
  'facultyId': instance.facultyId,
  'academicYearId': instance.academicYearId,
};

const _$MeRoleEnumMap = {MeRole.student: 'student', MeRole.admin: 'admin'};
