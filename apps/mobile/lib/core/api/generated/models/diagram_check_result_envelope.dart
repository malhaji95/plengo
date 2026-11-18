// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'diagram_check_result.dart';

part 'diagram_check_result_envelope.g.dart';

@JsonSerializable()
class DiagramCheckResultEnvelope {
  const DiagramCheckResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory DiagramCheckResultEnvelope.fromJson(Map<String, Object?> json) => _$DiagramCheckResultEnvelopeFromJson(json);
  
  final bool success;
  final DiagramCheckResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$DiagramCheckResultEnvelopeToJson(this);
}
