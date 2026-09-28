// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attempt.dart';

part 'attempt_envelope.g.dart';

@JsonSerializable()
class AttemptEnvelope {
  const AttemptEnvelope({required this.success, required this.data, required this.error});

  factory AttemptEnvelope.fromJson(Map<String, Object?> json) => _$AttemptEnvelopeFromJson(json);

  final bool success;
  final Attempt data;
  final dynamic error;

  Map<String, Object?> toJson() => _$AttemptEnvelopeToJson(this);
}
