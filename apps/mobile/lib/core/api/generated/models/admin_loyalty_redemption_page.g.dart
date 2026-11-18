// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_loyalty_redemption_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminLoyaltyRedemptionPage _$AdminLoyaltyRedemptionPageFromJson(
  Map<String, dynamic> json,
) => AdminLoyaltyRedemptionPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => AdminLoyaltyRedemption.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$AdminLoyaltyRedemptionPageToJson(
  AdminLoyaltyRedemptionPage instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
};
