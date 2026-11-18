// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_reward_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyRewardListEnvelope _$AdminLoyaltyRewardListEnvelopeFromJson(
  Map<String, dynamic> json,
) => AdminLoyaltyRewardListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => AdminLoyaltyReward.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$AdminLoyaltyRewardListEnvelopeToJson(
  AdminLoyaltyRewardListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
