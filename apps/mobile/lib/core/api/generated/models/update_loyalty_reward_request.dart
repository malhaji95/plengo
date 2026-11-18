// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward_kind.dart';

part 'update_loyalty_reward_request.g.dart';

@JsonSerializable()
class UpdateLoyaltyRewardRequest {
  const UpdateLoyaltyRewardRequest({
    this.titleAr,
    this.description,
    this.costPoints,
    this.kind,
    this.deckId,
    this.isActive,
    this.sortOrder,
  });
  
  factory UpdateLoyaltyRewardRequest.fromJson(Map<String, Object?> json) => _$UpdateLoyaltyRewardRequestFromJson(json);
  
  @JsonKey(includeIfNull: false)
  final String? titleAr;
  @JsonKey(includeIfNull: false)
  final String? description;
  @JsonKey(includeIfNull: false)
  final int? costPoints;
  @JsonKey(includeIfNull: false)
  final LoyaltyRewardKind? kind;
  @JsonKey(includeIfNull: false)
  final String? deckId;
  @JsonKey(includeIfNull: false)
  final bool? isActive;
  @JsonKey(includeIfNull: false)
  final int? sortOrder;

  Map<String, Object?> toJson() => _$UpdateLoyaltyRewardRequestToJson(this);
}
