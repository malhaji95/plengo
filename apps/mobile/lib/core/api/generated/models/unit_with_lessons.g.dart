// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_with_lessons.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitWithLessons _$UnitWithLessonsFromJson(Map<String, dynamic> json) =>
    UnitWithLessons(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      code: json['code'] as String,
      titleAr: json['titleAr'] as String,
      sortOrder: json['sortOrder'] as num,
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UnitWithLessonsToJson(UnitWithLessons instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'code': instance.code,
      'titleAr': instance.titleAr,
      'sortOrder': instance.sortOrder,
      'lessons': instance.lessons,
    };
