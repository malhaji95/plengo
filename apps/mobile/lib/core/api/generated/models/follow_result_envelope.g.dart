// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FollowResultEnvelope _$FollowResultEnvelopeFromJson(
  Map<String, dynamic> json,
) => FollowResultEnvelope(
  success: json['success'] as bool,
  data: FollowResult.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$FollowResultEnvelopeToJson(
  FollowResultEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
