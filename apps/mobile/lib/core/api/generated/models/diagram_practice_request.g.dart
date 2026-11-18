// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagram_practice_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiagramPracticeRequest _$DiagramPracticeRequestFromJson(
  Map<String, dynamic> json,
) => DiagramPracticeRequest(
  subjectId: json['subjectId'] as String,
  count: (json['count'] as num).toInt(),
  teacherTrackId: json['teacherTrackId'] as String?,
  unitId: json['unitId'] as String?,
  lessonIds: (json['lessonIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DiagramPracticeRequestToJson(
  DiagramPracticeRequest instance,
) => <String, dynamic>{
  'subjectId': instance.subjectId,
  'teacherTrackId': ?instance.teacherTrackId,
  'unitId': ?instance.unitId,
  'lessonIds': ?instance.lessonIds,
  'count': instance.count,
};
