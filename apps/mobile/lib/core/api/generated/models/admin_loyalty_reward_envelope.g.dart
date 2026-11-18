// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_reward_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyRewardEnvelope _$AdminLoyaltyRewardEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminLoyaltyRewardEnvelope(
  success: json['success'] as bool,
  data: AdminLoyaltyReward.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$AdminLoyaltyRewardEnvelopeToJson(
  AdminLoyaltyRewardEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
