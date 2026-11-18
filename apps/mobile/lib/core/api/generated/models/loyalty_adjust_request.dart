// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'loyalty_adjust_request.g.dart';

@JsonSerializable()
class LoyaltyAdjustRequest {
  const LoyaltyAdjustRequest({
    required this.delta,
    required this.note,
  });
  
  factory LoyaltyAdjustRequest.fromJson(Map<String, Object?> json) => _$LoyaltyAdjustRequestFromJson(json);
  
  final int delta;
  final String note;

  Map<String, Object?> toJson() => _$LoyaltyAdjustRequestToJson(this);
}
