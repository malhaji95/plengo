// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_loyalty_reward_list.dart';

part 'admin_loyalty_reward_list_envelope.g.dart';

@JsonSerializable()
class AdminLoyaltyRewardListEnvelope {
  const AdminLoyaltyRewardListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminLoyaltyRewardListEnvelope.fromJson(Map<String, Object?> json) => _$AdminLoyaltyRewardListEnvelopeFromJson(json);
  
  final bool success;
  final AdminLoyaltyRewardList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminLoyaltyRewardListEnvelopeToJson(this);
}
