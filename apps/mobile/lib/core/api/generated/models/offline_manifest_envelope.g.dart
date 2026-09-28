// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_manifest_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineManifestEnvelope _$OfflineManifestEnvelopeFromJson(Map<String, dynamic> json) => OfflineManifestEnvelope(
  success: json['success'] as bool,
  data: OfflineManifest.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineManifestEnvelopeToJson(OfflineManifestEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
