// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_entitlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyEntitlement _$MyEntitlementFromJson(Map<String, dynamic> json) =>
    MyEntitlement(
      id: json['id'] as String,
      scope: AccessScope.fromJson(json['scope'] as Map<String, dynamic>),
      source: $enumDecode(_$MyEntitlementSourceEnumMap, json['source']),
      startsAt: json['startsAt'] as String,
      expiresAt: json['expiresAt'] as String?,
      isPermanent: json['isPermanent'] as bool,
      state: $enumDecode(_$MyEntitlementStateEnumMap, json['state']),
    );

Map<String, dynamic> _$MyEntitlementToJson(MyEntitlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scope': instance.scope,
      'source': instance.source,
      'startsAt': instance.startsAt,
      'expiresAt': instance.expiresAt,
      'isPermanent': instance.isPermanent,
      'state': instance.state,
    };

const _$MyEntitlementSourceEnumMap = {
  MyEntitlementSource.coupon: 'coupon',
  MyEntitlementSource.adminGrant: 'admin_grant',
  MyEntitlementSource.promotion: 'promotion',
  MyEntitlementSource.futurePurchase: 'future_purchase',
};

const _$MyEntitlementStateEnumMap = {
  MyEntitlementState.active: 'active',
  MyEntitlementState.expired: 'expired',
  MyEntitlementState.revoked: 'revoked',
};
