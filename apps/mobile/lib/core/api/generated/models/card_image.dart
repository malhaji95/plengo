// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'card_image.g.dart';

@JsonSerializable()
class CardImage {
  const CardImage({
    required this.mediaId,
    required this.cacheKey,
    required this.fullUrl,
    required this.thumbUrl,
    required this.width,
    required this.height,
  });
  
  factory CardImage.fromJson(Map<String, Object?> json) => _$CardImageFromJson(json);
  
  final String mediaId;
  final String cacheKey;
  final String fullUrl;
  final String thumbUrl;
  @JsonKey(includeIfNull: true)
  final int? width;
  @JsonKey(includeIfNull: true)
  final int? height;

  Map<String, Object?> toJson() => _$CardImageToJson(this);
}
