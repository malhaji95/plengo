// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_redeem_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRedeemResultEnvelope _$LoyaltyRedeemResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltyRedeemResultEnvelope(
  success: json['success'] as bool,
  data: LoyaltyRedeemResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltyRedeemResultEnvelopeToJson(
  LoyaltyRedeemResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
