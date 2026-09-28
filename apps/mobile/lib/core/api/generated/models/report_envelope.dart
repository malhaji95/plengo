// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'report.dart';

part 'report_envelope.g.dart';

@JsonSerializable()
class ReportEnvelope {
  const ReportEnvelope({required this.success, required this.data, required this.error});

  factory ReportEnvelope.fromJson(Map<String, Object?> json) => _$ReportEnvelopeFromJson(json);

  final bool success;
  final Report data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ReportEnvelopeToJson(this);
}
