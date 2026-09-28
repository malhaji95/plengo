// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineScope _$OfflineScopeFromJson(Map<String, dynamic> json) => OfflineScope(
  scopeType: $enumDecode(_$OfflineScopeScopeTypeEnumMap, json['scopeType']),
  subjectId: json['subjectId'] as String?,
  teacherTrackId: json['teacherTrackId'] as String?,
);

Map<String, dynamic> _$OfflineScopeToJson(OfflineScope instance) => <String, dynamic>{
  'scopeType': instance.scopeType,
  'subjectId': instance.subjectId,
  'teacherTrackId': instance.teacherTrackId,
};

const _$OfflineScopeScopeTypeEnumMap = {
  OfflineScopeScopeType.subject: 'subject',
  OfflineScopeScopeType.teacherTrack: 'teacher_track',
};
