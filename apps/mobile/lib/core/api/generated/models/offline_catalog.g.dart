// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineCatalog _$OfflineCatalogFromJson(Map<String, dynamic> json) => OfflineCatalog(
  scopes: (json['scopes'] as List<dynamic>)
      .map((e) => OfflineScopeSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OfflineCatalogToJson(OfflineCatalog instance) => <String, dynamic>{'scopes': instance.scopes};
