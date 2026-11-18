// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_redemption.dart';

part 'loyalty_redeem_result.g.dart';

@JsonSerializable()
class LoyaltyRedeemResult {
  const LoyaltyRedeemResult({
    required this.redemption,
    required this.balance,
  });
  
  factory LoyaltyRedeemResult.fromJson(Map<String, Object?> json) => _$LoyaltyRedeemResultFromJson(json);
  
  final LoyaltyRedemption redemption;
  final int balance;

  Map<String, Object?> toJson() => _$LoyaltyRedeemResultToJson(this);
}
