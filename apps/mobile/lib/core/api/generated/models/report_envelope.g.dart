// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportEnvelope _$ReportEnvelopeFromJson(Map<String, dynamic> json) => ReportEnvelope(
  success: json['success'] as bool,
  data: Report.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$ReportEnvelopeToJson(ReportEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
