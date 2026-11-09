// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineManifest _$OfflineManifestFromJson(Map<String, dynamic> json) =>
    OfflineManifest(
      packKey: json['packKey'] as String,
      version: json['version'] as String,
      premium: json['premium'] as bool,
      normalizationVersion: (json['normalizationVersion'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => OfflineManifestItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfflineManifestToJson(OfflineManifest instance) =>
    <String, dynamic>{
      'packKey': instance.packKey,
      'version': instance.version,
      'premium': instance.premium,
      'normalizationVersion': instance.normalizationVersion,
      'items': instance.items,
    };
