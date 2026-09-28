// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaFile _$MediaFileFromJson(Map<String, dynamic> json) => MediaFile(
  id: json['id'] as String,
  kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
  status: $enumDecode(_$MediaFileStatusEnumMap, json['status']),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  version: (json['version'] as num).toInt(),
);

Map<String, dynamic> _$MediaFileToJson(MediaFile instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'status': instance.status,
  'width': instance.width,
  'height': instance.height,
  'version': instance.version,
};

const _$MediaKindEnumMap = {
  MediaKind.flashcard: 'flashcard',
  MediaKind.banner: 'banner',
  MediaKind.teacher: 'teacher',
  MediaKind.cover: 'cover',
  MediaKind.userCard: 'user-card',
  MediaKind.avatar: 'avatar',
};

const _$MediaFileStatusEnumMap = {
  MediaFileStatus.pending: 'pending',
  MediaFileStatus.ready: 'ready',
  MediaFileStatus.failed: 'failed',
};
