// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_overview_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatsOverviewEnvelope _$StatsOverviewEnvelopeFromJson(
  Map<String, dynamic> json,
) => StatsOverviewEnvelope(
  success: json['success'] as bool,
  data: StatsOverview.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$StatsOverviewEnvelopeToJson(
  StatsOverviewEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
