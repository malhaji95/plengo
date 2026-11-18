// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_redemption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRedemption _$LoyaltyRedemptionFromJson(Map<String, dynamic> json) =>
    LoyaltyRedemption(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      titleAr: json['titleAr'] as String,
      kind: $enumDecode(_$LoyaltyRewardKindEnumMap, json['kind']),
      costPoints: (json['costPoints'] as num).toInt(),
      deckId: json['deckId'] as String?,
      status: $enumDecode(_$LoyaltyRedemptionStatusEnumMap, json['status']),
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
      handledAt: json['handledAt'] as String?,
    );

Map<String, dynamic> _$LoyaltyRedemptionToJson(LoyaltyRedemption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rewardId': instance.rewardId,
      'titleAr': instance.titleAr,
      'kind': instance.kind,
      'costPoints': instance.costPoints,
      'deckId': instance.deckId,
      'status': instance.status,
      'note': instance.note,
      'createdAt': instance.createdAt,
      'handledAt': instance.handledAt,
    };

const _$LoyaltyRewardKindEnumMap = {
  LoyaltyRewardKind.unlockDeck: 'unlock_deck',
  LoyaltyRewardKind.custom: 'custom',
};

const _$LoyaltyRedemptionStatusEnumMap = {
  LoyaltyRedemptionStatus.pending: 'pending',
  LoyaltyRedemptionStatus.fulfilled: 'fulfilled',
  LoyaltyRedemptionStatus.cancelled: 'cancelled',
};
