// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'media_kind.dart';

part 'create_upload_request.g.dart';

@JsonSerializable()
class CreateUploadRequest {
  const CreateUploadRequest({required this.kind, required this.contentType, required this.size});

  factory CreateUploadRequest.fromJson(Map<String, Object?> json) => _$CreateUploadRequestFromJson(json);

  final MediaKind kind;
  final String contentType;
  final int size;

  Map<String, Object?> toJson() => _$CreateUploadRequestToJson(this);
}
