// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_summary_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltySummaryEnvelope _$LoyaltySummaryEnvelopeFromJson(
  Map<String, dynamic> json,
) => LoyaltySummaryEnvelope(
  success: json['success'] as bool,
  data: LoyaltySummary.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$LoyaltySummaryEnvelopeToJson(
  LoyaltySummaryEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
