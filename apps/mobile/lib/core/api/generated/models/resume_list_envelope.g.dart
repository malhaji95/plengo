// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResumeListEnvelope _$ResumeListEnvelopeFromJson(Map<String, dynamic> json) =>
    ResumeListEnvelope(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ResumeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'],
    );

Map<String, dynamic> _$ResumeListEnvelopeToJson(ResumeListEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
