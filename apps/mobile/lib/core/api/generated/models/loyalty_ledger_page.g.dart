// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_ledger_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyLedgerPage _$LoyaltyLedgerPageFromJson(Map<String, dynamic> json) =>
    LoyaltyLedgerPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => LoyaltyLedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LoyaltyLedgerPageToJson(LoyaltyLedgerPage instance) =>
    <String, dynamic>{'items': instance.items};
