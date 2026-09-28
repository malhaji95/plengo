// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'media_file_status.dart';
import 'media_kind.dart';

part 'media_file.g.dart';

@JsonSerializable()
class MediaFile {
  const MediaFile({
    required this.id,
    required this.kind,
    required this.status,
    required this.width,
    required this.height,
    required this.version,
  });

  factory MediaFile.fromJson(Map<String, Object?> json) => _$MediaFileFromJson(json);

  final String id;
  final MediaKind kind;
  final MediaFileStatus status;
  @JsonKey(includeIfNull: true)
  final int? width;
  @JsonKey(includeIfNull: true)
  final int? height;
  final int version;

  Map<String, Object?> toJson() => _$MediaFileToJson(this);
}
