// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_lease_scope_type.dart';
import 'offline_lease_status.dart';

part 'offline_lease.g.dart';

@JsonSerializable()
class OfflineLease {
  const OfflineLease({
    required this.scopeType,
    required this.subjectId,
    required this.teacherTrackId,
    required this.status,
    required this.expiresAt,
  });

  factory OfflineLease.fromJson(Map<String, Object?> json) => _$OfflineLeaseFromJson(json);

  final OfflineLeaseScopeType scopeType;
  @JsonKey(includeIfNull: true)
  final String? subjectId;
  @JsonKey(includeIfNull: true)
  final String? teacherTrackId;
  final OfflineLeaseStatus status;
  @JsonKey(includeIfNull: true)
  final String? expiresAt;

  Map<String, Object?> toJson() => _$OfflineLeaseToJson(this);
}
