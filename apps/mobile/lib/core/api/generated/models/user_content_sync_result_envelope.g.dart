// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content_sync_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContentSyncResultEnvelope _$UserContentSyncResultEnvelopeFromJson(Map<String, dynamic> json) =>
    UserContentSyncResultEnvelope(
      success: json['success'] as bool,
      data: UserContentSyncResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$UserContentSyncResultEnvelopeToJson(UserContentSyncResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
