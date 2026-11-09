// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_subject_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogSubjectListEnvelope _$CatalogSubjectListEnvelopeFromJson(
  Map<String, dynamic> json,
) => CatalogSubjectListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>)
      .map((e) => CatalogSubject.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$CatalogSubjectListEnvelopeToJson(
  CatalogSubjectListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
