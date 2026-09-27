// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'signed_in_result.dart';

part 'signed_in_result_envelope.g.dart';

@JsonSerializable()
class SignedInResultEnvelope {
  const SignedInResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory SignedInResultEnvelope.fromJson(Map<String, Object?> json) => _$SignedInResultEnvelopeFromJson(json);
  
  final bool success;
  final SignedInResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SignedInResultEnvelopeToJson(this);
}
