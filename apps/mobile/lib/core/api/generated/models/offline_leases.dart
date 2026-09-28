// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_lease.dart';

part 'offline_leases.g.dart';

@JsonSerializable()
class OfflineLeases {
  const OfflineLeases({required this.serverTime, required this.leases});

  factory OfflineLeases.fromJson(Map<String, Object?> json) => _$OfflineLeasesFromJson(json);

  final String serverTime;
  final List<OfflineLease> leases;

  Map<String, Object?> toJson() => _$OfflineLeasesToJson(this);
}
