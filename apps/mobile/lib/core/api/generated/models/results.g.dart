// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Results _$ResultsFromJson(Map<String, dynamic> json) => Results(
  clientAttemptId: json['clientAttemptId'] as String,
  status: $enumDecode(_$StatusEnumMap, json['status']),
  reason: json['reason'] as String?,
  attemptId: json['attemptId'] as String?,
  correctCount: (json['correctCount'] as num?)?.toInt(),
  totalCount: (json['totalCount'] as num?)?.toInt(),
  mismatches: (json['mismatches'] as num).toInt(),
);

Map<String, dynamic> _$ResultsToJson(Results instance) => <String, dynamic>{
  'clientAttemptId': instance.clientAttemptId,
  'status': instance.status,
  'reason': instance.reason,
  'attemptId': instance.attemptId,
  'correctCount': instance.correctCount,
  'totalCount': instance.totalCount,
  'mismatches': instance.mismatches,
};

const _$StatusEnumMap = {
  Status.accepted: 'accepted',
  Status.rejected: 'rejected',
};
