// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_loyalty_redemption_page.dart';

part 'admin_loyalty_redemption_page_envelope.g.dart';

@JsonSerializable()
class AdminLoyaltyRedemptionPageEnvelope {
  const AdminLoyaltyRedemptionPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory AdminLoyaltyRedemptionPageEnvelope.fromJson(Map<String, Object?> json) => _$AdminLoyaltyRedemptionPageEnvelopeFromJson(json);
  
  final bool success;
  final AdminLoyaltyRedemptionPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AdminLoyaltyRedemptionPageEnvelopeToJson(this);
}
