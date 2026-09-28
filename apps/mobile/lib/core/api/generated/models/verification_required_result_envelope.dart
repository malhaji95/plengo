// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'verification_required_result.dart';

part 'verification_required_result_envelope.g.dart';

@JsonSerializable()
class VerificationRequiredResultEnvelope {
  const VerificationRequiredResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory VerificationRequiredResultEnvelope.fromJson(Map<String, Object?> json) => _$VerificationRequiredResultEnvelopeFromJson(json);
  
  final bool success;
  final VerificationRequiredResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$VerificationRequiredResultEnvelopeToJson(this);
}
