// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward_kind.dart';

part 'admin_loyalty_reward.g.dart';

@JsonSerializable()
class AdminLoyaltyReward {
  const AdminLoyaltyReward({
    required this.id,
    required this.titleAr,
    required this.description,
    required this.costPoints,
    required this.kind,
    required this.deckId,
    required this.deckTitleAr,
    required this.isActive,
    required this.sortOrder,
    required this.redemptionCount,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AdminLoyaltyReward.fromJson(Map<String, Object?> json) => _$AdminLoyaltyRewardFromJson(json);
  
  final String id;
  final String titleAr;
  @JsonKey(includeIfNull: true)
  final String? description;
  final int costPoints;
  final LoyaltyRewardKind kind;
  @JsonKey(includeIfNull: true)
  final String? deckId;
  @JsonKey(includeIfNull: true)
  final String? deckTitleAr;
  final bool isActive;
  final int sortOrder;
  final int redemptionCount;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$AdminLoyaltyRewardToJson(this);
}
