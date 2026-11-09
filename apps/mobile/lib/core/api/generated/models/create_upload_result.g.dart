// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_upload_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUploadResult _$CreateUploadResultFromJson(Map<String, dynamic> json) =>
    CreateUploadResult(
      id: json['id'] as String,
      uploadUrl: json['uploadUrl'] as String,
      method: json['method'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$CreateUploadResultToJson(CreateUploadResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uploadUrl': instance.uploadUrl,
      'method': instance.method,
      'headers': instance.headers,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };
