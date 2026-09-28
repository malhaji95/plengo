// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_states_page.dart';

part 'srs_states_page_envelope.g.dart';

@JsonSerializable()
class SrsStatesPageEnvelope {
  const SrsStatesPageEnvelope({required this.success, required this.data, required this.error});

  factory SrsStatesPageEnvelope.fromJson(Map<String, Object?> json) => _$SrsStatesPageEnvelopeFromJson(json);

  final bool success;
  final SrsStatesPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SrsStatesPageEnvelopeToJson(this);
}
