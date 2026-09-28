// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_pack.dart';
import 'offline_scope.dart';

part 'offline_scope_catalog.g.dart';

@JsonSerializable()
class OfflineScopeCatalog {
  const OfflineScopeCatalog({
    required this.scope,
    required this.titleAr,
    required this.entitled,
    required this.packs,
    required this.sizeBytes,
  });

  factory OfflineScopeCatalog.fromJson(Map<String, Object?> json) => _$OfflineScopeCatalogFromJson(json);

  final OfflineScope scope;
  final String titleAr;
  final bool entitled;
  final List<OfflinePack> packs;
  final int sizeBytes;

  Map<String, Object?> toJson() => _$OfflineScopeCatalogToJson(this);
}
