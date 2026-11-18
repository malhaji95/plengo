// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward_kind.dart';

part 'create_loyalty_reward_request.g.dart';

@JsonSerializable()
class CreateLoyaltyRewardRequest {
  const CreateLoyaltyRewardRequest({
    required this.titleAr,
    required this.costPoints,
    required this.kind,
    this.description,
    this.deckId,
    this.isActive,
    this.sortOrder,
  });
  
  factory CreateLoyaltyRewardRequest.fromJson(Map<String, Object?> json) => _$CreateLoyaltyRewardRequestFromJson(json);
  
  final String titleAr;
  @JsonKey(includeIfNull: false)
  final String? description;
  final int costPoints;
  final LoyaltyRewardKind kind;
  @JsonKey(includeIfNull: false)
  final String? deckId;
  @JsonKey(includeIfNull: false)
  final bool? isActive;
  @JsonKey(includeIfNull: false)
  final int? sortOrder;

  Map<String, Object?> toJson() => _$CreateLoyaltyRewardRequestToJson(this);
}
