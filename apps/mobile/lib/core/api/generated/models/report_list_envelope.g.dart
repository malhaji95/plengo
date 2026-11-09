// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportListEnvelope _$ReportListEnvelopeFromJson(Map<String, dynamic> json) =>
    ReportListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$ReportListEnvelopeToJson(ReportListEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
