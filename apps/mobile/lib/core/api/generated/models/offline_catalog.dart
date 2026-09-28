// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_scope_summary.dart';

part 'offline_catalog.g.dart';

@JsonSerializable()
class OfflineCatalog {
  const OfflineCatalog({
    required this.scopes,
  });
  
  factory OfflineCatalog.fromJson(Map<String, Object?> json) => _$OfflineCatalogFromJson(json);
  
  final List<OfflineScopeSummary> scopes;

  Map<String, Object?> toJson() => _$OfflineCatalogToJson(this);
}
