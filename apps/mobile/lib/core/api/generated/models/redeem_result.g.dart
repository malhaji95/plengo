// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemResult _$RedeemResultFromJson(Map<String, dynamic> json) => RedeemResult(
  entitlement: MyEntitlement.fromJson(json['entitlement'] as Map<String, dynamic>),
  upgraded: json['upgraded'] as bool,
);

Map<String, dynamic> _$RedeemResultToJson(RedeemResult instance) => <String, dynamic>{
  'entitlement': instance.entitlement,
  'upgraded': instance.upgraded,
};
