// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_ledger_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyLedgerPageEnvelope _$LoyaltyLedgerPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltyLedgerPageEnvelope(
  success: json['success'] as bool,
  data: LoyaltyLedgerPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltyLedgerPageEnvelopeToJson(
  LoyaltyLedgerPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
