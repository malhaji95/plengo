// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward_kind.dart';

part 'loyalty_reward.g.dart';

@JsonSerializable()
class LoyaltyReward {
  const LoyaltyReward({
    required this.id,
    required this.titleAr,
    required this.description,
    required this.costPoints,
    required this.kind,
    required this.deckId,
    required this.deckTitleAr,
    required this.deckSubjectId,
    required this.alreadyOwned,
    required this.affordable,
    required this.sortOrder,
  });
  
  factory LoyaltyReward.fromJson(Map<String, Object?> json) => _$LoyaltyRewardFromJson(json);
  
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
  @JsonKey(includeIfNull: true)
  final String? deckSubjectId;
  final bool alreadyOwned;
  final bool affordable;
  final int sortOrder;

  Map<String, Object?> toJson() => _$LoyaltyRewardToJson(this);
}
