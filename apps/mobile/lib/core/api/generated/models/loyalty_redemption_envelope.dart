// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_redemption.dart';

part 'loyalty_redemption_envelope.g.dart';

@JsonSerializable()
class LoyaltyRedemptionEnvelope {
  const LoyaltyRedemptionEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltyRedemptionEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltyRedemptionEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltyRedemption data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltyRedemptionEnvelopeToJson(this);
}
