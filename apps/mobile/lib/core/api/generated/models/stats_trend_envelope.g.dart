// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_trend_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatsTrendEnvelope _$StatsTrendEnvelopeFromJson(Map<String, dynamic> json) =>
    StatsTrendEnvelope(
      success: json['success'] as bool,
      data: StatsTrend.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$StatsTrendEnvelopeToJson(StatsTrendEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
