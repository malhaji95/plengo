// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_item_type.dart';

part 'offline_manifest_item.g.dart';

@JsonSerializable()
class OfflineManifestItem {
  const OfflineManifestItem({required this.type, required this.id, required this.version});

  factory OfflineManifestItem.fromJson(Map<String, Object?> json) => _$OfflineManifestItemFromJson(json);

  final OfflineItemType type;
  final String id;
  final int version;

  Map<String, Object?> toJson() => _$OfflineManifestItemToJson(this);
}
