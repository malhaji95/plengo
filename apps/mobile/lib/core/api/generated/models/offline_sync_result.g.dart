// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineSyncResult _$OfflineSyncResultFromJson(Map<String, dynamic> json) =>
    OfflineSyncResult(
      results: (json['results'] as List<dynamic>)
          .map((e) => OfflineSyncOutcome.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfflineSyncResultToJson(OfflineSyncResult instance) =>
    <String, dynamic>{'results': instance.results};
