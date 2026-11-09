// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offline_image.g.dart';

@JsonSerializable()
class OfflineImage {
  const OfflineImage({
    required this.mediaId,
    required this.version,
    required this.url,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });
  
  factory OfflineImage.fromJson(Map<String, Object?> json) => _$OfflineImageFromJson(json);
  
  final String mediaId;
  final int version;
  final String url;
  @JsonKey(includeIfNull: true)
  final int? width;
  @JsonKey(includeIfNull: true)
  final int? height;
  final int sizeBytes;

  Map<String, Object?> toJson() => _$OfflineImageToJson(this);
}
