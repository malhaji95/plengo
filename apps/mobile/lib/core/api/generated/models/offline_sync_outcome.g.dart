// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineSyncOutcome _$OfflineSyncOutcomeFromJson(Map<String, dynamic> json) =>
    OfflineSyncOutcome(
      clientAttemptId: json['clientAttemptId'] as String,
      status: $enumDecode(_$OfflineSyncOutcomeStatusEnumMap, json['status']),
      reason: json['reason'] as String?,
      attemptId: json['attemptId'] as String?,
      correctCount: (json['correctCount'] as num?)?.toInt(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      mismatches: (json['mismatches'] as num).toInt(),
    );

Map<String, dynamic> _$OfflineSyncOutcomeToJson(OfflineSyncOutcome instance) =>
    <String, dynamic>{
      'clientAttemptId': instance.clientAttemptId,
      'status': instance.status,
      'reason': instance.reason,
      'attemptId': instance.attemptId,
      'correctCount': instance.correctCount,
      'totalCount': instance.totalCount,
      'mismatches': instance.mismatches,
    };

const _$OfflineSyncOutcomeStatusEnumMap = {
  OfflineSyncOutcomeStatus.accepted: 'accepted',
  OfflineSyncOutcomeStatus.rejected: 'rejected',
};
