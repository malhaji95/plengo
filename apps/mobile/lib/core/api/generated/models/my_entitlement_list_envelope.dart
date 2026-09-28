// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'my_entitlement_list.dart';

part 'my_entitlement_list_envelope.g.dart';

@JsonSerializable()
class MyEntitlementListEnvelope {
  const MyEntitlementListEnvelope({required this.success, required this.data, required this.error});

  factory MyEntitlementListEnvelope.fromJson(Map<String, Object?> json) => _$MyEntitlementListEnvelopeFromJson(json);

  final bool success;
  final MyEntitlementList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$MyEntitlementListEnvelopeToJson(this);
}
