// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_redemption_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyRedemptionPageEnvelope _$AdminLoyaltyRedemptionPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminLoyaltyRedemptionPageEnvelope(
  success: json['success'] as bool,
  data: AdminLoyaltyRedemptionPage.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
  error: json['error'],
);

Map<String, dynamic> _$AdminLoyaltyRedemptionPageEnvelopeToJson(
  AdminLoyaltyRedemptionPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
