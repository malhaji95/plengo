// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_list.dart';

part 'session_list_envelope.g.dart';

@JsonSerializable()
class SessionListEnvelope {
  const SessionListEnvelope({required this.success, required this.data, required this.error});

  factory SessionListEnvelope.fromJson(Map<String, Object?> json) => _$SessionListEnvelopeFromJson(json);

  final bool success;
  final SessionList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$SessionListEnvelopeToJson(this);
}
