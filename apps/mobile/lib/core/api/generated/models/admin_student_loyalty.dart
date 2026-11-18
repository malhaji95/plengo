// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_ledger_entry.dart';
import 'loyalty_redemption.dart';

part 'admin_student_loyalty.g.dart';

@JsonSerializable()
class AdminStudentLoyalty {
  const AdminStudentLoyalty({
    required this.userId,
    required this.balance,
    required this.earnedToday,
    required this.ledger,
    required this.redemptions,
    required this.unlockedDeckIds,
  });
  
  factory AdminStudentLoyalty.fromJson(Map<String, Object?> json) => _$AdminStudentLoyaltyFromJson(json);
  
  final String userId;
  final int balance;
  final int earnedToday;
  final List<LoyaltyLedgerEntry> ledger;
  final List<LoyaltyRedemption> redemptions;
  final List<String> unlockedDeckIds;

  Map<String, Object?> toJson() => _$AdminStudentLoyaltyToJson(this);
}
