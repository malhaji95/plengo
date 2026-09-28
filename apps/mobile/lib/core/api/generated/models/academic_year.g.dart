// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_year.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcademicYear _$AcademicYearFromJson(Map<String, dynamic> json) => AcademicYear(
  id: json['id'] as String,
  code: json['code'] as String,
  nameAr: json['nameAr'] as String,
  sortOrder: json['sortOrder'] as num,
  isActive: json['isActive'] as bool,
  facultyId: json['facultyId'] as String,
);

Map<String, dynamic> _$AcademicYearToJson(AcademicYear instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'nameAr': instance.nameAr,
  'sortOrder': instance.sortOrder,
  'isActive': instance.isActive,
  'facultyId': instance.facultyId,
};
