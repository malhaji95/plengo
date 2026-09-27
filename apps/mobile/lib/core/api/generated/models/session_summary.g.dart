// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    SessionSummary(
      id: json['id'] as String,
      platform: $enumDecode(_$SessionPlatformEnumMap, json['platform']),
      appVersion: json['appVersion'] as String?,
      userAgent: json['userAgent'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
      current: json['current'] as bool,
    );

Map<String, dynamic> _$SessionSummaryToJson(SessionSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': _$SessionPlatformEnumMap[instance.platform]!,
      'appVersion': instance.appVersion,
      'userAgent': instance.userAgent,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastSeenAt': instance.lastSeenAt.toIso8601String(),
      'current': instance.current,
    };

const _$SessionPlatformEnumMap = {
  SessionPlatform.android: 'android',
  SessionPlatform.ios: 'ios',
  SessionPlatform.web: 'web',
  SessionPlatform.admin: 'admin',
};
