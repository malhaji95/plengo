// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogSubject _$CatalogSubjectFromJson(Map<String, dynamic> json) =>
    CatalogSubject(
      id: json['id'] as String,
      educationLevelId: json['educationLevelId'] as String,
      universityId: json['universityId'] as String?,
      facultyId: json['facultyId'] as String?,
      academicYearId: json['academicYearId'] as String?,
      code: json['code'] as String,
      nameAr: json['nameAr'] as String,
      description: json['description'] as String?,
      coverMediaId: json['coverMediaId'] as String?,
      coverUrl: json['coverUrl'] as String?,
      sortOrder: json['sortOrder'] as num,
      isActive: json['isActive'] as bool,
      hasAccess: json['hasAccess'] as bool,
    );

Map<String, dynamic> _$CatalogSubjectToJson(CatalogSubject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'educationLevelId': instance.educationLevelId,
      'universityId': instance.universityId,
      'facultyId': instance.facultyId,
      'academicYearId': instance.academicYearId,
      'code': instance.code,
      'nameAr': instance.nameAr,
      'description': instance.description,
      'coverMediaId': instance.coverMediaId,
      'coverUrl': instance.coverUrl,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'hasAccess': instance.hasAccess,
    };
