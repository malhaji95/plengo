// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sent_result.dart';

part 'sent_result_envelope.g.dart';

@JsonSerializable()
class SentResultEnvelope {
  const SentResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory SentResultEnvelope.fromJson(Map<String, Object?> json) => _$SentResultEnvelopeFromJson(json);
  
  final bool success;
  final SentResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SentResultEnvelopeToJson(this);
}
