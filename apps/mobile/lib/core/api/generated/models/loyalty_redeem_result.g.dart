// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_redeem_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRedeemResult _$LoyaltyRedeemResultFromJson(Map<String, dynamic> json) =>
    LoyaltyRedeemResult(
      redemption: LoyaltyRedemption.fromJson(
        json['redemption'] as Map<String, dynamic>,
      ),
      balance: (json['balance'] as num).toInt(),
    );

Map<String, dynamic> _$LoyaltyRedeemResultToJson(
  LoyaltyRedeemResult instance,
) => <String, dynamic>{
  'redemption': instance.redemption,
  'balance': instance.balance,
};
