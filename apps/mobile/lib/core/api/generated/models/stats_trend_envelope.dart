// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stats_trend.dart';

part 'stats_trend_envelope.g.dart';

@JsonSerializable()
class StatsTrendEnvelope {
  const StatsTrendEnvelope({required this.success, required this.data, required this.error});

  factory StatsTrendEnvelope.fromJson(Map<String, Object?> json) => _$StatsTrendEnvelopeFromJson(json);

  final bool success;
  final StatsTrend data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StatsTrendEnvelopeToJson(this);
}
