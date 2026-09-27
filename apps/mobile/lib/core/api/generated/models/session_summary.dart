// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_platform.dart';

part 'session_summary.g.dart';

@JsonSerializable()
class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.platform,
    required this.appVersion,
    required this.userAgent,
    required this.createdAt,
    required this.lastSeenAt,
    required this.current,
  });
  
  factory SessionSummary.fromJson(Map<String, Object?> json) => _$SessionSummaryFromJson(json);
  
  final String id;
  final SessionPlatform platform;
  final String? appVersion;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool current;

  Map<String, Object?> toJson() => _$SessionSummaryToJson(this);
}
