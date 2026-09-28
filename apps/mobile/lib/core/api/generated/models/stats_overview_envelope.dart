// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stats_overview.dart';

part 'stats_overview_envelope.g.dart';

@JsonSerializable()
class StatsOverviewEnvelope {
  const StatsOverviewEnvelope({required this.success, required this.data, required this.error});

  factory StatsOverviewEnvelope.fromJson(Map<String, Object?> json) => _$StatsOverviewEnvelopeFromJson(json);

  final bool success;
  final StatsOverview data;
  final dynamic error;

  Map<String, Object?> toJson() => _$StatsOverviewEnvelopeToJson(this);
}
