// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'report_list.dart';

part 'report_list_envelope.g.dart';

@JsonSerializable()
class ReportListEnvelope {
  const ReportListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory ReportListEnvelope.fromJson(Map<String, Object?> json) => _$ReportListEnvelopeFromJson(json);
  
  final bool success;
  final ReportList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ReportListEnvelopeToJson(this);
}
