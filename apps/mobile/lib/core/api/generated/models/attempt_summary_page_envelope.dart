// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt_summary_page.dart';

part 'attempt_summary_page_envelope.g.dart';

@JsonSerializable()
class AttemptSummaryPageEnvelope {
  const AttemptSummaryPageEnvelope({required this.success, required this.data, required this.error});

  factory AttemptSummaryPageEnvelope.fromJson(Map<String, Object?> json) => _$AttemptSummaryPageEnvelopeFromJson(json);

  final bool success;
  final AttemptSummaryPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AttemptSummaryPageEnvelopeToJson(this);
}
