// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'signed_out_result.dart';

part 'signed_out_result_envelope.g.dart';

@JsonSerializable()
class SignedOutResultEnvelope {
  const SignedOutResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory SignedOutResultEnvelope.fromJson(Map<String, Object?> json) => _$SignedOutResultEnvelopeFromJson(json);
  
  final bool success;
  final SignedOutResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SignedOutResultEnvelopeToJson(this);
}
