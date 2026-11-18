// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_loyalty_reward_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLoyaltyRewardRequest _$CreateLoyaltyRewardRequestFromJson(
  Map<String, dynamic> json,
) => CreateLoyaltyRewardRequest(
  titleAr: json['titleAr'] as String,
  costPoints: (json['costPoints'] as num).toInt(),
  kind: $enumDecode(_$LoyaltyRewardKindEnumMap, json['kind']),
  description: json['description'] as String?,
  deckId: json['deckId'] as String?,
  isActive: json['isActive'] as bool?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateLoyaltyRewardRequestToJson(
  CreateLoyaltyRewardRequest instance,
) => <String, dynamic>{
  'titleAr': instance.titleAr,
  'description': ?instance.description,
  'costPoints': instance.costPoints,
  'kind': instance.kind,
  'deckId': ?instance.deckId,
  'isActive': ?instance.isActive,
  'sortOrder': ?instance.sortOrder,
};

const _$LoyaltyRewardKindEnumMap = {
  LoyaltyRewardKind.unlockDeck: 'unlock_deck',
  LoyaltyRewardKind.custom: 'custom',
};
