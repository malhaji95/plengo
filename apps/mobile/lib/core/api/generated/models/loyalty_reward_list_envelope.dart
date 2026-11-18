// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_reward_list.dart';

part 'loyalty_reward_list_envelope.g.dart';

@JsonSerializable()
class LoyaltyRewardListEnvelope {
  const LoyaltyRewardListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltyRewardListEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltyRewardListEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltyRewardList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltyRewardListEnvelopeToJson(this);
}
