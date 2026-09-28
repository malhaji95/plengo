// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_stats_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectStatsEnvelope _$SubjectStatsEnvelopeFromJson(Map<String, dynamic> json) => SubjectStatsEnvelope(
  success: json['success'] as bool,
  data: SubjectStats.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SubjectStatsEnvelopeToJson(SubjectStatsEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
