// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reason.dart';

part 'loyalty_ledger_entry.g.dart';

@JsonSerializable()
class LoyaltyLedgerEntry {
  const LoyaltyLedgerEntry({
    required this.id,
    required this.delta,
    required this.reason,
    required this.refId,
    required this.day,
    required this.note,
    required this.createdAt,
  });
  
  factory LoyaltyLedgerEntry.fromJson(Map<String, Object?> json) => _$LoyaltyLedgerEntryFromJson(json);
  
  final String id;
  final int delta;
  final LoyaltyReason reason;
  @JsonKey(includeIfNull: true)
  final String? refId;
  final String day;
  @JsonKey(includeIfNull: true)
  final String? note;
  final String createdAt;

  Map<String, Object?> toJson() => _$LoyaltyLedgerEntryToJson(this);
}
