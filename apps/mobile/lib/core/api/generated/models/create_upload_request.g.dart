// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_upload_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUploadRequest _$CreateUploadRequestFromJson(Map<String, dynamic> json) =>
    CreateUploadRequest(
      kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
      contentType: json['contentType'] as String,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$CreateUploadRequestToJson(
  CreateUploadRequest instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'contentType': instance.contentType,
  'size': instance.size,
};

const _$MediaKindEnumMap = {
  MediaKind.flashcard: 'flashcard',
  MediaKind.banner: 'banner',
  MediaKind.teacher: 'teacher',
  MediaKind.cover: 'cover',
  MediaKind.userCard: 'user-card',
};
