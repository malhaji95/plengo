// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_attempt.dart';

part 'offline_sync_request.g.dart';

@JsonSerializable()
class OfflineSyncRequest {
  const OfflineSyncRequest({required this.attempts});

  factory OfflineSyncRequest.fromJson(Map<String, Object?> json) => _$OfflineSyncRequestFromJson(json);

  final List<OfflineAttempt> attempts;

  Map<String, Object?> toJson() => _$OfflineSyncRequestToJson(this);
}
