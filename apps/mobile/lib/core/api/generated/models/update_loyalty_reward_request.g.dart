// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_loyalty_reward_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateLoyaltyRewardRequest _$UpdateLoyaltyRewardRequestFromJson(
  Map<String, dynamic> json,
) => UpdateLoyaltyRewardRequest(
  titleAr: json['titleAr'] as String?,
  description: json['description'] as String?,
  costPoints: (json['costPoints'] as num?)?.toInt(),
  kind: $enumDecodeNullable(_$LoyaltyRewardKindEnumMap, json['kind']),
  deckId: json['deckId'] as String?,
  isActive: json['isActive'] as bool?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$UpdateLoyaltyRewardRequestToJson(
  UpdateLoyaltyRewardRequest instance,
) => <String, dynamic>{
  'titleAr': ?instance.titleAr,
  'description': ?instance.description,
  'costPoints': ?instance.costPoints,
  'kind': ?instance.kind,
  'deckId': ?instance.deckId,
  'isActive': ?instance.isActive,
  'sortOrder': ?instance.sortOrder,
};

const _$LoyaltyRewardKindEnumMap = {
  LoyaltyRewardKind.unlockDeck: 'unlock_deck',
  LoyaltyRewardKind.custom: 'custom',
};
