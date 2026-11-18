// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_loyalty_redemption.dart';

part 'admin_loyalty_redemption_page.g.dart';

@JsonSerializable()
class AdminLoyaltyRedemptionPage {
  const AdminLoyaltyRedemptionPage({
    required this.items,
    required this.nextCursor,
  });
  
  factory AdminLoyaltyRedemptionPage.fromJson(Map<String, Object?> json) => _$AdminLoyaltyRedemptionPageFromJson(json);
  
  final List<AdminLoyaltyRedemption> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$AdminLoyaltyRedemptionPageToJson(this);
}
