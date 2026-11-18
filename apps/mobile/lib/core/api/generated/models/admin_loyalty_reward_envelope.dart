// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_loyalty_reward.dart';

part 'admin_loyalty_reward_envelope.g.dart';

@JsonSerializable()
class AdminLoyaltyRewardEnvelope {
  const AdminLoyaltyRewardEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminLoyaltyRewardEnvelope.fromJson(Map<String, Object?> json) => _$AdminLoyaltyRewardEnvelopeFromJson(json);
  
  final bool success;
  final AdminLoyaltyReward data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminLoyaltyRewardEnvelopeToJson(this);
}
