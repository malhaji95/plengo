// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_settings.dart';

part 'loyalty_settings_envelope.g.dart';

@JsonSerializable()
class LoyaltySettingsEnvelope {
  const LoyaltySettingsEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltySettingsEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltySettingsEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltySettings data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltySettingsEnvelopeToJson(this);
}
