// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scopes2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scopes2 _$Scopes2FromJson(Map<String, dynamic> json) => Scopes2(
  scopeType: $enumDecode(_$ScopeTypeEnumMap, json['scopeType']),
  subjectId: json['subjectId'] as String?,
  teacherTrackId: json['teacherTrackId'] as String?,
);

Map<String, dynamic> _$Scopes2ToJson(Scopes2 instance) => <String, dynamic>{
  'scopeType': instance.scopeType,
  'subjectId': ?instance.subjectId,
  'teacherTrackId': ?instance.teacherTrackId,
};

const _$ScopeTypeEnumMap = {
  ScopeType.subject: 'subject',
  ScopeType.teacherTrack: 'teacher_track',
};
