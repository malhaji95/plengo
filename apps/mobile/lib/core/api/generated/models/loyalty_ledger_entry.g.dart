// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_ledger_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyLedgerEntry _$LoyaltyLedgerEntryFromJson(Map<String, dynamic> json) =>
    LoyaltyLedgerEntry(
      id: json['id'] as String,
      delta: (json['delta'] as num).toInt(),
      reason: $enumDecode(_$LoyaltyReasonEnumMap, json['reason']),
      refId: json['refId'] as String?,
      day: json['day'] as String,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$LoyaltyLedgerEntryToJson(LoyaltyLedgerEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'delta': instance.delta,
      'reason': instance.reason,
      'refId': instance.refId,
      'day': instance.day,
      'note': instance.note,
      'createdAt': instance.createdAt,
    };

const _$LoyaltyReasonEnumMap = {
  LoyaltyReason.review: 'review',
  LoyaltyReason.correctAnswer: 'correct_answer',
  LoyaltyReason.redemption: 'redemption',
  LoyaltyReason.refund: 'refund',
  LoyaltyReason.adminAdjust: 'admin_adjust',
};
