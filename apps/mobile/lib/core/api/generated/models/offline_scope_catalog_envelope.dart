// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_scope_catalog.dart';

part 'offline_scope_catalog_envelope.g.dart';

@JsonSerializable()
class OfflineScopeCatalogEnvelope {
  const OfflineScopeCatalogEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory OfflineScopeCatalogEnvelope.fromJson(Map<String, Object?> json) => _$OfflineScopeCatalogEnvelopeFromJson(json);
  
  final bool success;
  final OfflineScopeCatalog data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineScopeCatalogEnvelopeToJson(this);
}
