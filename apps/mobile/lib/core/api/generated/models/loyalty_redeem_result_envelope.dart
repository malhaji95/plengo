// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_redeem_result.dart';

part 'loyalty_redeem_result_envelope.g.dart';

@JsonSerializable()
class LoyaltyRedeemResultEnvelope {
  const LoyaltyRedeemResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltyRedeemResultEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltyRedeemResultEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltyRedeemResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltyRedeemResultEnvelopeToJson(this);
}
