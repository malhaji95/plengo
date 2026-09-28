// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_sync_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsSyncResultEnvelope _$SrsSyncResultEnvelopeFromJson(Map<String, dynamic> json) => SrsSyncResultEnvelope(
  success: json['success'] as bool,
  data: SrsSyncResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$SrsSyncResultEnvelopeToJson(SrsSyncResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
