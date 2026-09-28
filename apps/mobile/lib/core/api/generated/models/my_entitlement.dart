// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'access_scope.dart';
import 'my_entitlement_source.dart';
import 'my_entitlement_state.dart';

part 'my_entitlement.g.dart';

@JsonSerializable()
class MyEntitlement {
  const MyEntitlement({
    required this.id,
    required this.scope,
    required this.source,
    required this.startsAt,
    required this.expiresAt,
    required this.isPermanent,
    required this.state,
  });
  
  factory MyEntitlement.fromJson(Map<String, Object?> json) => _$MyEntitlementFromJson(json);
  
  final String id;
  final AccessScope scope;
  final MyEntitlementSource source;
  final String startsAt;
  @JsonKey(includeIfNull: true)
  final String? expiresAt;
  final bool isPermanent;
  final MyEntitlementState state;

  Map<String, Object?> toJson() => _$MyEntitlementToJson(this);
}
