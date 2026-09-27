// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'verified_result.dart';

part 'verified_result_envelope.g.dart';

@JsonSerializable()
class VerifiedResultEnvelope {
  const VerifiedResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory VerifiedResultEnvelope.fromJson(Map<String, Object?> json) => _$VerifiedResultEnvelopeFromJson(json);
  
  final bool success;
  final VerifiedResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$VerifiedResultEnvelopeToJson(this);
}
