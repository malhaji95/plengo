// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'remote_config.dart';

part 'remote_config_envelope.g.dart';

@JsonSerializable()
class RemoteConfigEnvelope {
  const RemoteConfigEnvelope({required this.success, required this.data, required this.error});

  factory RemoteConfigEnvelope.fromJson(Map<String, Object?> json) => _$RemoteConfigEnvelopeFromJson(json);

  final bool success;
  final RemoteConfig data;
  final dynamic error;

  Map<String, Object?> toJson() => _$RemoteConfigEnvelopeToJson(this);
}
