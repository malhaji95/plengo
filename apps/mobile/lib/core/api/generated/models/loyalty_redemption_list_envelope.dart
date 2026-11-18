// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_redemption_list.dart';

part 'loyalty_redemption_list_envelope.g.dart';

@JsonSerializable()
class LoyaltyRedemptionListEnvelope {
  const LoyaltyRedemptionListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltyRedemptionListEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltyRedemptionListEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltyRedemptionList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltyRedemptionListEnvelopeToJson(this);
}
