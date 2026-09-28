// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_sync_outcome.dart';

part 'offline_sync_result.g.dart';

@JsonSerializable()
class OfflineSyncResult {
  const OfflineSyncResult({required this.results});

  factory OfflineSyncResult.fromJson(Map<String, Object?> json) => _$OfflineSyncResultFromJson(json);

  final List<OfflineSyncOutcome> results;

  Map<String, Object?> toJson() => _$OfflineSyncResultToJson(this);
}
