// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faculty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Faculty _$FacultyFromJson(Map<String, dynamic> json) => Faculty(
  id: json['id'] as String,
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  sortOrder: json['sortOrder'] as num,
  isActive: json['isActive'] as bool,
  universityId: json['universityId'] as String,
);

Map<String, dynamic> _$FacultyToJson(Faculty instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
  'universityId': instance.universityId,
};
