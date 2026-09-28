// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'university.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

University _$UniversityFromJson(Map<String, dynamic> json) => University(
  id: json['id'] as String,
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  sortOrder: json['sortOrder'] as num,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$UniversityToJson(University instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'nameAr': instance.nameAr,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
    };
