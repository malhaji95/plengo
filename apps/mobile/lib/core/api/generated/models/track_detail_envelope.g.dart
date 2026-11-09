// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_detail_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrackDetailEnvelope _$TrackDetailEnvelopeFromJson(Map<String, dynamic> json) =>
    TrackDetailEnvelope(
      success: json['success'] as bool,
      data: TrackDetail.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$TrackDetailEnvelopeToJson(
  TrackDetailEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
