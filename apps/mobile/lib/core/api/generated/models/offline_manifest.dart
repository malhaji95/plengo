// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_manifest_item.dart';

part 'offline_manifest.g.dart';

@JsonSerializable()
class OfflineManifest {
  const OfflineManifest({
    required this.packKey,
    required this.version,
    required this.premium,
    required this.normalizationVersion,
    required this.items,
  });
  
  factory OfflineManifest.fromJson(Map<String, Object?> json) => _$OfflineManifestFromJson(json);
  
  final String packKey;
  final String version;
  final bool premium;
  final int normalizationVersion;
  final List<OfflineManifestItem> items;

  Map<String, Object?> toJson() => _$OfflineManifestToJson(this);
}
