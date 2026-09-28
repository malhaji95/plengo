// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_upload_result.g.dart';

@JsonSerializable()
class CreateUploadResult {
  const CreateUploadResult({
    required this.id,
    required this.uploadUrl,
    required this.method,
    required this.headers,
    required this.expiresAt,
  });

  factory CreateUploadResult.fromJson(Map<String, Object?> json) => _$CreateUploadResultFromJson(json);

  final String id;
  final String uploadUrl;
  final String method;
  final Map<String, String> headers;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => _$CreateUploadResultToJson(this);
}
