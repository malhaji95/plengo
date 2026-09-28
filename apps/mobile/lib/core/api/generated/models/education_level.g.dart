// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'education_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EducationLevel _$EducationLevelFromJson(Map<String, dynamic> json) => EducationLevel(
  id: json['id'] as String,
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  sortOrder: json['sortOrder'] as num,
  isCollege: json['isCollege'] as bool,
);

Map<String, dynamic> _$EducationLevelToJson(EducationLevel instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'sortOrder': instance.sortOrder,
  'isCollege': instance.isCollege,
};
