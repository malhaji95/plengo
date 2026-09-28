// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_leases_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineLeasesEnvelope _$OfflineLeasesEnvelopeFromJson(
  Map<String, dynamic> json,
) => OfflineLeasesEnvelope(
  success: json['success'] as bool,
  data: OfflineLeases.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineLeasesEnvelopeToJson(
  OfflineLeasesEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
