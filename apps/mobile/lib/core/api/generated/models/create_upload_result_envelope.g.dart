// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_upload_result_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUploadResultEnvelope _$CreateUploadResultEnvelopeFromJson(Map<String, dynamic> json) =>
    CreateUploadResultEnvelope(
      success: json['success'] as bool,
      data: CreateUploadResult.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$CreateUploadResultEnvelopeToJson(CreateUploadResultEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
