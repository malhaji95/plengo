// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'read_result.dart';

part 'read_result_envelope.g.dart';

@JsonSerializable()
class ReadResultEnvelope {
  const ReadResultEnvelope({required this.success, required this.data, required this.error});

  factory ReadResultEnvelope.fromJson(Map<String, Object?> json) => _$ReadResultEnvelopeFromJson(json);

  final bool success;
  final ReadResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$ReadResultEnvelopeToJson(this);
}
