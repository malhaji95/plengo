// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_scope_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineScopeCatalog _$OfflineScopeCatalogFromJson(Map<String, dynamic> json) => OfflineScopeCatalog(
  scope: OfflineScope.fromJson(json['scope'] as Map<String, dynamic>),
  titleAr: json['titleAr'] as String,
  entitled: json['entitled'] as bool,
  packs: (json['packs'] as List<dynamic>).map((e) => OfflinePack.fromJson(e as Map<String, dynamic>)).toList(),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
);

Map<String, dynamic> _$OfflineScopeCatalogToJson(OfflineScopeCatalog instance) => <String, dynamic>{
  'scope': instance.scope,
  'titleAr': instance.titleAr,
  'entitled': instance.entitled,
  'packs': instance.packs,
  'sizeBytes': instance.sizeBytes,
};
