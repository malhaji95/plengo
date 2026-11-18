// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_reward_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyRewardListEnvelope _$LoyaltyRewardListEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltyRewardListEnvelope(
  success: json['success'] as bool,
  data: LoyaltyRewardList.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltyRewardListEnvelopeToJson(
  LoyaltyRewardListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
