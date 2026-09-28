// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'me.dart';

part 'me_envelope.g.dart';

@JsonSerializable()
class MeEnvelope {
  const MeEnvelope({required this.success, required this.data, required this.error});

  factory MeEnvelope.fromJson(Map<String, Object?> json) => _$MeEnvelopeFromJson(json);

  final bool success;
  final Me data;
  final dynamic error;

  Map<String, Object?> toJson() => _$MeEnvelopeToJson(this);
}
