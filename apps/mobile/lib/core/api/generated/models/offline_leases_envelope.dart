// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_leases.dart';

part 'offline_leases_envelope.g.dart';

@JsonSerializable()
class OfflineLeasesEnvelope {
  const OfflineLeasesEnvelope({required this.success, required this.data, required this.error});

  factory OfflineLeasesEnvelope.fromJson(Map<String, Object?> json) => _$OfflineLeasesEnvelopeFromJson(json);

  final bool success;
  final OfflineLeases data;
  final dynamic error;

  Map<String, Object?> toJson() => _$OfflineLeasesEnvelopeToJson(this);
}
