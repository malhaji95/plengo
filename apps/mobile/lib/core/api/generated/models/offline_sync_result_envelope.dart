// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_sync_result.dart';

part 'offline_sync_result_envelope.g.dart';

@JsonSerializable()
class OfflineSyncResultEnvelope {
  const OfflineSyncResultEnvelope({required this.success, required this.data, required this.error});

  factory OfflineSyncResultEnvelope.fromJson(Map<String, Object?> json) => _$OfflineSyncResultEnvelopeFromJson(json);

  final bool success;
  final OfflineSyncResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineSyncResultEnvelopeToJson(this);
}
