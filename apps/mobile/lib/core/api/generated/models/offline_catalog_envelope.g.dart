// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_catalog_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineCatalogEnvelope _$OfflineCatalogEnvelopeFromJson(Map<String, dynamic> json) => OfflineCatalogEnvelope(
  success: json['success'] as bool,
  data: OfflineCatalog.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineCatalogEnvelopeToJson(OfflineCatalogEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
