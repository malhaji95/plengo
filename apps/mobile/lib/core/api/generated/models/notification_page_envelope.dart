// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_page.dart';

part 'notification_page_envelope.g.dart';

@JsonSerializable()
class NotificationPageEnvelope {
  const NotificationPageEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory NotificationPageEnvelope.fromJson(Map<String, Object?> json) => _$NotificationPageEnvelopeFromJson(json);
  
  final bool success;
  final NotificationPage data;
  final dynamic error;

  Map<String, Object?> toJson() => _$NotificationPageEnvelopeToJson(this);
}
