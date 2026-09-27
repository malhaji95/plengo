// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'track_detail.dart';

part 'track_detail_envelope.g.dart';

@JsonSerializable()
class TrackDetailEnvelope {
  const TrackDetailEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory TrackDetailEnvelope.fromJson(Map<String, Object?> json) => _$TrackDetailEnvelopeFromJson(json);
  
  final bool success;
  final TrackDetail data;
  final dynamic error;

  Map<String, Object?> toJson() => _$TrackDetailEnvelopeToJson(this);
}
