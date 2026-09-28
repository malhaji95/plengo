// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content_changes_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContentChangesEnvelope _$UserContentChangesEnvelopeFromJson(Map<String, dynamic> json) =>
    UserContentChangesEnvelope(
      success: json['success'] as bool,
      data: UserContentChanges.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$UserContentChangesEnvelopeToJson(UserContentChangesEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
