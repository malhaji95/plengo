// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'catalog_subject_list.dart';

part 'catalog_subject_list_envelope.g.dart';

@JsonSerializable()
class CatalogSubjectListEnvelope {
  const CatalogSubjectListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory CatalogSubjectListEnvelope.fromJson(Map<String, Object?> json) => _$CatalogSubjectListEnvelopeFromJson(json);
  
  final bool success;
  final CatalogSubjectList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$CatalogSubjectListEnvelopeToJson(this);
}
