// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scope_access.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScopeAccess _$ScopeAccessFromJson(Map<String, dynamic> json) => ScopeAccess(
  hasAccess: json['hasAccess'] as bool,
  reason: $enumDecodeNullable(_$ScopeAccessReasonEnumMap, json['reason']),
  isPermanent: json['isPermanent'] as bool,
  entitlementExpiresAt: json['entitlementExpiresAt'] as String?,
  promotionTitleAr: json['promotionTitleAr'] as String?,
  promotionEndsAt: json['promotionEndsAt'] as String?,
);

Map<String, dynamic> _$ScopeAccessToJson(ScopeAccess instance) =>
    <String, dynamic>{
      'hasAccess': instance.hasAccess,
      'reason': instance.reason,
      'isPermanent': instance.isPermanent,
      'entitlementExpiresAt': instance.entitlementExpiresAt,
      'promotionTitleAr': instance.promotionTitleAr,
      'promotionEndsAt': instance.promotionEndsAt,
    };

const _$ScopeAccessReasonEnumMap = {
  ScopeAccessReason.entitlement: 'entitlement',
  ScopeAccessReason.promotion: 'promotion',
};
