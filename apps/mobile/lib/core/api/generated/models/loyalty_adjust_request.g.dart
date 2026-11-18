// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_adjust_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltyAdjustRequest _$LoyaltyAdjustRequestFromJson(
  Map<String, dynamic> json,
) => LoyaltyAdjustRequest(
  delta: (json['delta'] as num).toInt(),
  note: json['note'] as String,
);

Map<String, dynamic> _$LoyaltyAdjustRequestToJson(
  LoyaltyAdjustRequest instance,
) => <String, dynamic>{'delta': instance.delta, 'note': instance.note};
