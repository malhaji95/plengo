// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redeem_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedeemResultEnvelope _$RedeemResultEnvelopeFromJson(Map<String, dynamic> json) => RedeemResultEnvelope(
  success: json['success'] as bool,
  data: RedeemResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$RedeemResultEnvelopeToJson(RedeemResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
