// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'loyalty_settings.g.dart';

@JsonSerializable()
class LoyaltySettings {
  const LoyaltySettings({
    required this.enabled,
    required this.pointsPerReview,
    required this.dailyCap,
    required this.pointsPerCorrectQuestion,
  });
  
  factory LoyaltySettings.fromJson(Map<String, Object?> json) => _$LoyaltySettingsFromJson(json);
  
  final bool enabled;
  final int pointsPerReview;
  final int dailyCap;
  final int pointsPerCorrectQuestion;

  Map<String, Object?> toJson() => _$LoyaltySettingsToJson(this);
}
