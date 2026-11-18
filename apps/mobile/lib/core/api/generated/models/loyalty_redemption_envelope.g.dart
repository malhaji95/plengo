// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_redemption_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRedemptionEnvelope _$LoyaltyRedemptionEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltyRedemptionEnvelope(
  success: json['success'] as bool,
  data: LoyaltyRedemption.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltyRedemptionEnvelopeToJson(
  LoyaltyRedemptionEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
