// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'loyalty_summary.dart';

part 'loyalty_summary_envelope.g.dart';

@JsonSerializable()
class LoyaltySummaryEnvelope {
  const LoyaltySummaryEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory LoyaltySummaryEnvelope.fromJson(Map<String, Object?> json) => _$LoyaltySummaryEnvelopeFromJson(json);
  
  final bool success;
  final LoyaltySummary data;
  final dynamic error;

  Map<String, Object?> toJson() => _$LoyaltySummaryEnvelopeToJson(this);
}
