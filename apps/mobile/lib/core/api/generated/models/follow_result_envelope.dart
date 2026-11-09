// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'follow_result.dart';

part 'follow_result_envelope.g.dart';

@JsonSerializable()
class FollowResultEnvelope {
  const FollowResultEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory FollowResultEnvelope.fromJson(Map<String, Object?> json) => _$FollowResultEnvelopeFromJson(json);
  
  final bool success;
  final FollowResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$FollowResultEnvelopeToJson(this);
}
