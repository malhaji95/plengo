// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'deleted_result.dart';

part 'deleted_result_envelope.g.dart';

@JsonSerializable()
class DeletedResultEnvelope {
  const DeletedResultEnvelope({required this.success, required this.data, required this.error});

  factory DeletedResultEnvelope.fromJson(Map<String, Object?> json) => _$DeletedResultEnvelopeFromJson(json);

  final bool success;
  final DeletedResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$DeletedResultEnvelopeToJson(this);
}
