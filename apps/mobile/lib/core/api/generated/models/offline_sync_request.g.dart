// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineSyncRequest _$OfflineSyncRequestFromJson(Map<String, dynamic> json) =>
    OfflineSyncRequest(
      attempts: (json['attempts'] as List<dynamic>)
          .map((e) => OfflineAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfflineSyncRequestToJson(OfflineSyncRequest instance) =>
    <String, dynamic>{'attempts': instance.attempts};
