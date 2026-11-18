// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_ledger_entry.dart';

part 'loyalty_ledger_page.g.dart';

@JsonSerializable()
class LoyaltyLedgerPage {
  const LoyaltyLedgerPage({
    required this.items,
  });
  
  factory LoyaltyLedgerPage.fromJson(Map<String, Object?> json) => _$LoyaltyLedgerPageFromJson(json);
  
  final List<LoyaltyLedgerEntry> items;

  Map<String, Object?> toJson() => _$LoyaltyLedgerPageToJson(this);
}
