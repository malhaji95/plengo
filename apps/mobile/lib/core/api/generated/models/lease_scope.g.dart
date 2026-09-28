// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease_scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaseScope _$LeaseScopeFromJson(Map<String, dynamic> json) => LeaseScope(
  scopeType: $enumDecode(_$LeaseScopeScopeTypeEnumMap, json['scopeType']),
  subjectId: json['subjectId'] as String?,
  teacherTrackId: json['teacherTrackId'] as String?,
);

Map<String, dynamic> _$LeaseScopeToJson(LeaseScope instance) => <String, dynamic>{
  'scopeType': instance.scopeType,
  'subjectId': ?instance.subjectId,
  'teacherTrackId': ?instance.teacherTrackId,
};

const _$LeaseScopeScopeTypeEnumMap = {
  LeaseScopeScopeType.subject: 'subject',
  LeaseScopeScopeType.teacherTrack: 'teacher_track',
};
