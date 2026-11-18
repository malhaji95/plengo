// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_import_result.dart';

part 'diagram_import_result_envelope.g.dart';

@JsonSerializable()
class DiagramImportResultEnvelope {
  const DiagramImportResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory DiagramImportResultEnvelope.fromJson(Map<String, Object?> json) => _$DiagramImportResultEnvelopeFromJson(json);
  
  final bool success;
  final DiagramImportResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$DiagramImportResultEnvelopeToJson(this);
}
