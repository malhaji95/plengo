// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_pack_kind.dart';

part 'offline_pack.g.dart';

@JsonSerializable()
class OfflinePack {
  const OfflinePack({
    required this.packKey,
    required this.kind,
    required this.unitId,
    required this.deckId,
    required this.titleAr,
    required this.itemCount,
    required this.sizeBytes,
    required this.version,
    required this.premium,
  });
  
  factory OfflinePack.fromJson(Map<String, Object?> json) => _$OfflinePackFromJson(json);
  
  final String packKey;
  final OfflinePackKind kind;
  @JsonKey(includeIfNull: true)
  final String? unitId;
  @JsonKey(includeIfNull: true)
  final String? deckId;
  final String titleAr;
  final int itemCount;
  final int sizeBytes;
  final String version;
  final bool premium;

  Map<String, Object?> toJson() => _$OfflinePackToJson(this);
}
