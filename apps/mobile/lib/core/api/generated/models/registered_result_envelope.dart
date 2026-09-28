// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'registered_result.dart';

part 'registered_result_envelope.g.dart';

@JsonSerializable()
class RegisteredResultEnvelope {
  const RegisteredResultEnvelope({required this.success, required this.data, required this.error});

  factory RegisteredResultEnvelope.fromJson(Map<String, Object?> json) => _$RegisteredResultEnvelopeFromJson(json);

  final bool success;
  final RegisteredResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$RegisteredResultEnvelopeToJson(this);
}
