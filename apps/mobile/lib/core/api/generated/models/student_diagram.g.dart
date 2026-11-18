// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_diagram.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDiagram _$StudentDiagramFromJson(Map<String, dynamic> json) =>
    StudentDiagram(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      teacherTrackId: json['teacherTrackId'] as String?,
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      titleAr: json['titleAr'] as String,
      labelCount: (json['labelCount'] as num).toInt(),
      isFree: json['isFree'] as bool,
      locked: json['locked'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$StudentDiagramToJson(StudentDiagram instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'unitId': instance.unitId,
      'lessonId': instance.lessonId,
      'titleAr': instance.titleAr,
      'labelCount': instance.labelCount,
      'isFree': instance.isFree,
      'locked': instance.locked,
      'sortOrder': instance.sortOrder,
    };
