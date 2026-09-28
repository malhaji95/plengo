// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'my_entitlement.dart';

part 'redeem_result.g.dart';

@JsonSerializable()
class RedeemResult {
  const RedeemResult({required this.entitlement, required this.upgraded});

  factory RedeemResult.fromJson(Map<String, Object?> json) => _$RedeemResultFromJson(json);

  final MyEntitlement entitlement;
  final bool upgraded;

  Map<String, Object?> toJson() => _$RedeemResultToJson(this);
}
