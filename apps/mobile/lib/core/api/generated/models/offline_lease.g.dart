// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_lease.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineLease _$OfflineLeaseFromJson(Map<String, dynamic> json) => OfflineLease(
  scopeType: $enumDecode(_$OfflineLeaseScopeTypeEnumMap, json['scopeType']),
  subjectId: json['subjectId'] as String?,
  teacherTrackId: json['teacherTrackId'] as String?,
  status: $enumDecode(_$OfflineLeaseStatusEnumMap, json['status']),
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$OfflineLeaseToJson(OfflineLease instance) =>
    <String, dynamic>{
      'scopeType': instance.scopeType,
      'subjectId': instance.subjectId,
      'teacherTrackId': instance.teacherTrackId,
      'status': instance.status,
      'expiresAt': instance.expiresAt,
    };

const _$OfflineLeaseScopeTypeEnumMap = {
  OfflineLeaseScopeType.subject: 'subject',
  OfflineLeaseScopeType.teacherTrack: 'teacher_track',
};

const _$OfflineLeaseStatusEnumMap = {
  OfflineLeaseStatus.active: 'active',
  OfflineLeaseStatus.none: 'none',
};
