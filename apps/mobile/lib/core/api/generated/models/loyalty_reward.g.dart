// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_reward.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyReward _$LoyaltyRewardFromJson(Map<String, dynamic> json) =>
    LoyaltyReward(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      description: json['description'] as String?,
      costPoints: (json['costPoints'] as num).toInt(),
      kind: $enumDecode(_$LoyaltyRewardKindEnumMap, json['kind']),
      deckId: json['deckId'] as String?,
      deckTitleAr: json['deckTitleAr'] as String?,
      deckSubjectId: json['deckSubjectId'] as String?,
      alreadyOwned: json['alreadyOwned'] as bool,
      affordable: json['affordable'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
    );

Map<String, dynamic> _$LoyaltyRewardToJson(LoyaltyReward instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleAr': instance.titleAr,
      'description': instance.description,
      'costPoints': instance.costPoints,
      'kind': instance.kind,
      'deckId': instance.deckId,
      'deckTitleAr': instance.deckTitleAr,
      'deckSubjectId': instance.deckSubjectId,
      'alreadyOwned': instance.alreadyOwned,
      'affordable': instance.affordable,
      'sortOrder': instance.sortOrder,
    };

const _$LoyaltyRewardKindEnumMap = {
  LoyaltyRewardKind.unlockDeck: 'unlock_deck',
  LoyaltyRewardKind.custom: 'custom',
};
