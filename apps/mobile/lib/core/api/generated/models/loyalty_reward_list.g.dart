// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_reward_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRewardList _$LoyaltyRewardListFromJson(Map<String, dynamic> json) =>
    LoyaltyRewardList(
      balance: (json['balance'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LoyaltyRewardListToJson(LoyaltyRewardList instance) =>
    <String, dynamic>{'balance': instance.balance, 'items': instance.items};
