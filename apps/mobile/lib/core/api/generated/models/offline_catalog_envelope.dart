// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_catalog.dart';

part 'offline_catalog_envelope.g.dart';

@JsonSerializable()
class OfflineCatalogEnvelope {
  const OfflineCatalogEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory OfflineCatalogEnvelope.fromJson(Map<String, Object?> json) => _$OfflineCatalogEnvelopeFromJson(json);
  
  final bool success;
  final OfflineCatalog data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineCatalogEnvelopeToJson(this);
}
