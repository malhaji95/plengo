// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_ledger_page.dart';

part 'loyalty_ledger_page_envelope.g.dart';

@JsonSerializable()
class LoyaltyLedgerPageEnvelope {
  const LoyaltyLedgerPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltyLedgerPageEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltyLedgerPageEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltyLedgerPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltyLedgerPageEnvelopeToJson(this);
}
