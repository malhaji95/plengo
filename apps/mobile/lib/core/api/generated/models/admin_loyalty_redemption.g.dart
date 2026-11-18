// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_redemption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyRedemption _$AdminLoyaltyRedemptionFromJson(
  Map<String, dynamic> json,
) => AdminLoyaltyRedemption(
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
  userId: json['userId'] as String,
  studentEmail: json['studentEmail'] as String?,
  studentName: json['studentName'] as String?,
  handledByAdminId: json['handledByAdminId'] as String?,
);

Map<String, dynamic> _$AdminLoyaltyRedemptionToJson(
  AdminLoyaltyRedemption instance,
) => <String, dynamic>{
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
  'userId': instance.userId,
  'studentEmail': instance.studentEmail,
  'studentName': instance.studentName,
  'handledByAdminId': instance.handledByAdminId,
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
