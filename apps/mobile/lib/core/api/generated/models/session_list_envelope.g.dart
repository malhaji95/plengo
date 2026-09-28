// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionListEnvelope _$SessionListEnvelopeFromJson(Map<String, dynamic> json) =>
    SessionListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$SessionListEnvelopeToJson(
  SessionListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
