// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_redemption_status.dart';
import 'loyalty_reward_kind.dart';

part 'loyalty_redemption.g.dart';

@JsonSerializable()
class LoyaltyRedemption {
  const LoyaltyRedemption({
    required this.id,
    required this.rewardId,
    required this.titleAr,
    required this.kind,
    required this.costPoints,
    required this.deckId,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.handledAt,
  });
  
  factory LoyaltyRedemption.fromJson(Map<String, Object?> json) => _$LoyaltyRedemptionFromJson(json);
  
  final String id;
  final String rewardId;
  final String titleAr;
  final LoyaltyRewardKind kind;
  final int costPoints;
  @JsonKey(includeIfNull: true)
  final String? deckId;
  final LoyaltyRedemptionStatus status;
  @JsonKey(includeIfNull: true)
  final String? note;
  final String createdAt;
  @JsonKey(includeIfNull: true)
  final String? handledAt;

  Map<String, Object?> toJson() => _$LoyaltyRedemptionToJson(this);
}
