// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_scope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessScope _$AccessScopeFromJson(Map<String, dynamic> json) => AccessScope(
  scopeType: $enumDecode(_$AccessScopeScopeTypeEnumMap, json['scopeType']),
  subjectId: json['subjectId'] as String,
  teacherTrackId: json['teacherTrackId'] as String?,
  subjectNameAr: json['subjectNameAr'] as String,
  trackTitleAr: json['trackTitleAr'] as String?,
  teacherNameAr: json['teacherNameAr'] as String?,
  educationLevelId: json['educationLevelId'] as String,
);

Map<String, dynamic> _$AccessScopeToJson(AccessScope instance) => <String, dynamic>{
  'scopeType': instance.scopeType,
  'subjectId': instance.subjectId,
  'teacherTrackId': instance.teacherTrackId,
  'subjectNameAr': instance.subjectNameAr,
  'trackTitleAr': instance.trackTitleAr,
  'teacherNameAr': instance.teacherNameAr,
  'educationLevelId': instance.educationLevelId,
};

const _$AccessScopeScopeTypeEnumMap = {
  AccessScopeScopeType.subject: 'subject',
  AccessScopeScopeType.teacherTrack: 'teacher_track',
};
