// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'scope_access_reason.dart';

part 'scope_access.g.dart';

@JsonSerializable()
class ScopeAccess {
  const ScopeAccess({
    required this.hasAccess,
    required this.reason,
    required this.isPermanent,
    required this.entitlementExpiresAt,
    required this.promotionTitleAr,
    required this.promotionEndsAt,
  });

  factory ScopeAccess.fromJson(Map<String, Object?> json) => _$ScopeAccessFromJson(json);

  final bool hasAccess;
  @JsonKey(includeIfNull: true)
  final ScopeAccessReason? reason;
  final bool isPermanent;
  @JsonKey(includeIfNull: true)
  final String? entitlementExpiresAt;
  @JsonKey(includeIfNull: true)
  final String? promotionTitleAr;
  @JsonKey(includeIfNull: true)
  final String? promotionEndsAt;

  Map<String, Object?> toJson() => _$ScopeAccessToJson(this);
}
