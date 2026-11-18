// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyReward _$AdminLoyaltyRewardFromJson(Map<String, dynamic> json) =>
    AdminLoyaltyReward(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      description: json['description'] as String?,
      costPoints: (json['costPoints'] as num).toInt(),
      kind: $enumDecode(_$LoyaltyRewardKindEnumMap, json['kind']),
      deckId: json['deckId'] as String?,
      deckTitleAr: json['deckTitleAr'] as String?,
      isActive: json['isActive'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
      redemptionCount: (json['redemptionCount'] as num).toInt(),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$AdminLoyaltyRewardToJson(AdminLoyaltyReward instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'costPoints': instance.costPoints,
      'kind': instance.kind,
      'deckId': instance.deckId,
      'deckTitleAr': instance.deckTitleAr,
      'isActive': instance.isActive,
      'sortOrder': instance.sortOrder,
      'redemptionCount': instance.redemptionCount,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$LoyaltyRewardKindEnumMap = {
  LoyaltyRewardKind.unlockDeck: 'unlock_deck',
  LoyaltyRewardKind.custom: 'custom',
};
