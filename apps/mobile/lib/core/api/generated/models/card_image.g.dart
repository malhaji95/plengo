// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardImage _$CardImageFromJson(Map<String, dynamic> json) => CardImage(
  mediaId: json['mediaId'] as String,
  cacheKey: json['cacheKey'] as String,
  fullUrl: json['fullUrl'] as String,
  thumbUrl: json['thumbUrl'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
);

Map<String, dynamic> _$CardImageToJson(CardImage instance) => <String, dynamic>{
  'mediaId': instance.mediaId,
  'cacheKey': instance.cacheKey,
  'fullUrl': instance.fullUrl,
  'thumbUrl': instance.thumbUrl,
  'width': instance.width,
  'height': instance.height,
};
