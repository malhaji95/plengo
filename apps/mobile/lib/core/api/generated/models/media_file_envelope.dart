// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'media_file.dart';

part 'media_file_envelope.g.dart';

@JsonSerializable()
class MediaFileEnvelope {
  const MediaFileEnvelope({required this.success, required this.data, required this.error});

  factory MediaFileEnvelope.fromJson(Map<String, Object?> json) => _$MediaFileEnvelopeFromJson(json);

  final bool success;
  final MediaFile data;
  final dynamic error;

  Map<String, Object?> toJson() => _$MediaFileEnvelopeToJson(this);
}
