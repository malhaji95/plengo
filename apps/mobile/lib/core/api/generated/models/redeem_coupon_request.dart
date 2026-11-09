// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'redeem_coupon_request.g.dart';

@JsonSerializable()
class RedeemCouponRequest {
  const RedeemCouponRequest({
    required this.code,
  });
  
  factory RedeemCouponRequest.fromJson(Map<String, Object?> json) => _$RedeemCouponRequestFromJson(json);
  
  final String code;

  Map<String, Object?> toJson() => _$RedeemCouponRequestToJson(this);
}
