// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_settings.dart';

part 'loyalty_summary.g.dart';

@JsonSerializable()
class LoyaltySummary {
  const LoyaltySummary({
    required this.enabled,
    required this.balance,
    required this.earnedToday,
    required this.dailyCap,
    required this.remainingToday,
    required this.day,
    required this.rules,
  });
  
  factory LoyaltySummary.fromJson(Map<String, Object?> json) => _$LoyaltySummaryFromJson(json);
  
  final bool enabled;
  final int balance;
  final int earnedToday;
  final int dailyCap;
  @JsonKey(includeIfNull: true)
  final int? remainingToday;
  final String day;
  final LoyaltySettings rules;

  Map<String, Object?> toJson() => _$LoyaltySummaryToJson(this);
}
