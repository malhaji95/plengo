// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_rejection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncRejection _$SyncRejectionFromJson(Map<String, dynamic> json) =>
    SyncRejection(
      type: $enumDecode(_$SyncRejectionTypeEnumMap, json['type']),
      id: json['id'] as String,
      code: $enumDecode(_$SyncRejectionCodeEnumMap, json['code']),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$SyncRejectionToJson(SyncRejection instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'code': instance.code,
      'reason': instance.reason,
    };

const _$SyncRejectionTypeEnumMap = {
  SyncRejectionType.deck: 'deck',
  SyncRejectionType.card: 'card',
};

const _$SyncRejectionCodeEnumMap = {
  SyncRejectionCode.quotaExceeded: 'QUOTA_EXCEEDED',
  SyncRejectionCode.validationError: 'VALIDATION_ERROR',
  SyncRejectionCode.contentLocked: 'CONTENT_LOCKED',
  SyncRejectionCode.notFound: 'NOT_FOUND',
};
