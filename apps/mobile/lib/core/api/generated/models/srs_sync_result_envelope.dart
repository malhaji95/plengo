// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_sync_result.dart';

part 'srs_sync_result_envelope.g.dart';

@JsonSerializable()
class SrsSyncResultEnvelope {
  const SrsSyncResultEnvelope({required this.success, required this.data, required this.error});

  factory SrsSyncResultEnvelope.fromJson(Map<String, Object?> json) => _$SrsSyncResultEnvelopeFromJson(json);

  final bool success;
  final SrsSyncResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SrsSyncResultEnvelopeToJson(this);
}
