// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_redemption_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRedemptionListEnvelope _$LoyaltyRedemptionListEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltyRedemptionListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => LoyaltyRedemption.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltyRedemptionListEnvelopeToJson(
  LoyaltyRedemptionListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
