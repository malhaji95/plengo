// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineSyncResultEnvelope _$OfflineSyncResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => OfflineSyncResultEnvelope(
  success: json['success'] as bool,
  data: OfflineSyncResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineSyncResultEnvelopeToJson(
  OfflineSyncResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
