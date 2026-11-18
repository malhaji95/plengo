// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_student_loyalty.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminStudentLoyalty _$AdminStudentLoyaltyFromJson(Map<String, dynamic> json) =>
    AdminStudentLoyalty(
      userId: json['userId'] as String,
      balance: (json['balance'] as num).toInt(),
      earnedToday: (json['earnedToday'] as num).toInt(),
      ledger: (json['ledger'] as List<dynamic>)
          .map((e) => LoyaltyLedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      redemptions: (json['redemptions'] as List<dynamic>)
          .map((e) => LoyaltyRedemption.fromJson(e as Map<String, dynamic>))
          .toList(),
      unlockedDeckIds: (json['unlockedDeckIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AdminStudentLoyaltyToJson(
  AdminStudentLoyalty instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'balance': instance.balance,
  'earnedToday': instance.earnedToday,
  'ledger': instance.ledger,
  'redemptions': instance.redemptions,
  'unlockedDeckIds': instance.unlockedDeckIds,
};
