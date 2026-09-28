// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_preferences.dart';

part 'notification_preferences_envelope.g.dart';

@JsonSerializable()
class NotificationPreferencesEnvelope {
  const NotificationPreferencesEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory NotificationPreferencesEnvelope.fromJson(Map<String, Object?> json) => _$NotificationPreferencesEnvelopeFromJson(json);
  
  final bool success;
  final NotificationPreferences data;
  final dynamic error;

  Map<String, Object?> toJson() => _$NotificationPreferencesEnvelopeToJson(this);
}
