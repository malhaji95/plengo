// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineImage _$OfflineImageFromJson(Map<String, dynamic> json) => OfflineImage(
  mediaId: json['mediaId'] as String,
  version: (json['version'] as num).toInt(),
  url: json['url'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
);

Map<String, dynamic> _$OfflineImageToJson(OfflineImage instance) => <String, dynamic>{
  'mediaId': instance.mediaId,
  'version': instance.version,
  'url': instance.url,
  'width': instance.width,
  'height': instance.height,
  'sizeBytes': instance.sizeBytes,
};
