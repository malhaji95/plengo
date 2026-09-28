// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_scope_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineScopeSummary _$OfflineScopeSummaryFromJson(Map<String, dynamic> json) => OfflineScopeSummary(
  scope: OfflineScope.fromJson(json['scope'] as Map<String, dynamic>),
  titleAr: json['titleAr'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  packCount: (json['packCount'] as num).toInt(),
);

Map<String, dynamic> _$OfflineScopeSummaryToJson(OfflineScopeSummary instance) => <String, dynamic>{
  'scope': instance.scope,
  'titleAr': instance.titleAr,
  'sizeBytes': instance.sizeBytes,
  'packCount': instance.packCount,
};
