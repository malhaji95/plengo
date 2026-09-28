// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'scope_progress.dart';

part 'scope_progress_envelope.g.dart';

@JsonSerializable()
class ScopeProgressEnvelope {
  const ScopeProgressEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory ScopeProgressEnvelope.fromJson(Map<String, Object?> json) => _$ScopeProgressEnvelopeFromJson(json);
  
  final bool success;
  final ScopeProgress data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ScopeProgressEnvelopeToJson(this);
}
