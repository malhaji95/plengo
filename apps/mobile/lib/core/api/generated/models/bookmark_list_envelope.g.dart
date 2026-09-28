// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkListEnvelope _$BookmarkListEnvelopeFromJson(
  Map<String, dynamic> json,
) => BookmarkListEnvelope(
  success: json['success'] as bool,
  data: BookmarkList.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$BookmarkListEnvelopeToJson(
  BookmarkListEnvelope instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
