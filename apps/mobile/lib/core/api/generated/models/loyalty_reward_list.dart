// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward.dart';

part 'loyalty_reward_list.g.dart';

@JsonSerializable()
class LoyaltyRewardList {
  const LoyaltyRewardList({
    required this.balance,
    required this.items,
  });
  
  factory LoyaltyRewardList.fromJson(Map<String, Object?> json) => _$LoyaltyRewardListFromJson(json);
  
  final int balance;
  final List<LoyaltyReward> items;

  Map<String, Object?> toJson() => _$LoyaltyRewardListToJson(this);
}
