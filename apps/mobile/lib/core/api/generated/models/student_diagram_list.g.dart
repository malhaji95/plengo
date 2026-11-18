// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_diagram_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentDiagramList _$StudentDiagramListFromJson(Map<String, dynamic> json) =>
    StudentDiagramList(
      items: (json['items'] as List<dynamic>)
          .map((e) => StudentDiagram.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num).toInt(),
      accessibleCount: (json['accessibleCount'] as num).toInt(),
      lockedCount: (json['lockedCount'] as num).toInt(),
    );

Map<String, dynamic> _$StudentDiagramListToJson(StudentDiagramList instance) =>
    <String, dynamic>{
      'items': instance.items,
      'totalCount': instance.totalCount,
      'accessibleCount': instance.accessibleCount,
      'lockedCount': instance.lockedCount,
    };
