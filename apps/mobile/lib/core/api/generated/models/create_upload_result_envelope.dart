// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'create_upload_result.dart';

part 'create_upload_result_envelope.g.dart';

@JsonSerializable()
class CreateUploadResultEnvelope {
  const CreateUploadResultEnvelope({required this.success, required this.data, required this.error});

  factory CreateUploadResultEnvelope.fromJson(Map<String, Object?> json) => _$CreateUploadResultEnvelopeFromJson(json);

  final bool success;
  final CreateUploadResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$CreateUploadResultEnvelopeToJson(this);
}
