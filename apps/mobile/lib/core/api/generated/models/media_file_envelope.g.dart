// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_file_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaFileEnvelope _$MediaFileEnvelopeFromJson(Map<String, dynamic> json) => MediaFileEnvelope(
  success: json['success'] as bool,
  data: MediaFile.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$MediaFileEnvelopeToJson(MediaFileEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
