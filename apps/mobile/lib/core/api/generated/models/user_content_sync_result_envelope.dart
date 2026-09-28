// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_content_sync_result.dart';

part 'user_content_sync_result_envelope.g.dart';

@JsonSerializable()
class UserContentSyncResultEnvelope {
  const UserContentSyncResultEnvelope({required this.success, required this.data, required this.error});

  factory UserContentSyncResultEnvelope.fromJson(Map<String, Object?> json) =>
      _$UserContentSyncResultEnvelopeFromJson(json);

  final bool success;
  final UserContentSyncResult data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UserContentSyncResultEnvelopeToJson(this);
}
