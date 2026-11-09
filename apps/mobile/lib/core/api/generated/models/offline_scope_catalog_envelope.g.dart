// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_scope_catalog_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineScopeCatalogEnvelope _$OfflineScopeCatalogEnvelopeFromJson(
  Map<String, dynamic> json,
) => OfflineScopeCatalogEnvelope(
  success: json['success'] as bool,
  data: OfflineScopeCatalog.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OfflineScopeCatalogEnvelopeToJson(
  OfflineScopeCatalogEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
