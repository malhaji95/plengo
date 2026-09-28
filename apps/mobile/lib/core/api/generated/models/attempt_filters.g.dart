// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptFilters _$AttemptFiltersFromJson(Map<String, dynamic> json) =>
    AttemptFilters(
      subjectId: json['subjectId'] as String?,
      teacherTrackId: json['teacherTrackId'] as String?,
      unitId: json['unitId'] as String?,
      lessonId: json['lessonId'] as String?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$AttemptFiltersTypesEnumMap, e))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
      questionIds: (json['questionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AttemptFiltersToJson(AttemptFilters instance) =>
    <String, dynamic>{
      'subjectId': ?instance.subjectId,
      'teacherTrackId': ?instance.teacherTrackId,
      'unitId': ?instance.unitId,
      'lessonId': ?instance.lessonId,
      'types': ?instance.types,
      'count': ?instance.count,
      'questionIds': ?instance.questionIds,
    };

const _$AttemptFiltersTypesEnumMap = {
  AttemptFiltersTypes.mcq: 'mcq',
  AttemptFiltersTypes.trueFalse: 'true_false',
  AttemptFiltersTypes.written: 'written',
};
