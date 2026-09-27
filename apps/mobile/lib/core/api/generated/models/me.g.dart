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
);

Map<String, dynamic> _$MeToJson(Me instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'emailVerified': instance.emailVerified,
  'role': _$MeRoleEnumMap[instance.role]!,
  'fullName': instance.fullName,
  'educationLevelId': instance.educationLevelId,
};

const _$MeRoleEnumMap = {MeRole.student: 'student', MeRole.admin: 'admin'};
