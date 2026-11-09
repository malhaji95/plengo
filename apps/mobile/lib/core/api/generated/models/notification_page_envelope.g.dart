// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPageEnvelope _$NotificationPageEnvelopeFromJson(
  Map<String, dynamic> json,
) => NotificationPageEnvelope(
  success: json['success'] as bool,
  data: NotificationPage.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$NotificationPageEnvelopeToJson(
  NotificationPageEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
