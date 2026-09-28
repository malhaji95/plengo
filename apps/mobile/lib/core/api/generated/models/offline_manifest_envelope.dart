// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_manifest.dart';

part 'offline_manifest_envelope.g.dart';

@JsonSerializable()
class OfflineManifestEnvelope {
  const OfflineManifestEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory OfflineManifestEnvelope.fromJson(Map<String, Object?> json) => _$OfflineManifestEnvelopeFromJson(json);
  
  final bool success;
  final OfflineManifest data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineManifestEnvelopeToJson(this);
}
