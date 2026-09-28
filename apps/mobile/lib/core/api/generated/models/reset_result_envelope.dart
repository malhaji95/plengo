// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reset_result.dart';

part 'reset_result_envelope.g.dart';

@JsonSerializable()
class ResetResultEnvelope {
  const ResetResultEnvelope({required this.success, required this.data, required this.error});

  factory ResetResultEnvelope.fromJson(Map<String, Object?> json) => _$ResetResultEnvelopeFromJson(json);

  final bool success;
  final ResetResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ResetResultEnvelopeToJson(this);
}
