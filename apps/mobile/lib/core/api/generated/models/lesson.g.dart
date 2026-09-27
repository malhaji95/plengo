// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  unitId: json['unitId'] as String?,
  code: json['code'] as String,
  titleAr: json['titleAr'] as String,
  sortOrder: json['sortOrder'] as num,
);

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'subjectId': instance.subjectId,
  'unitId': instance.unitId,
  'code': instance.code,
  'titleAr': instance.titleAr,
  'sortOrder': instance.sortOrder,
};
