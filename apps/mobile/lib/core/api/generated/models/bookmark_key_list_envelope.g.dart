// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_key_list_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkKeyListEnvelope _$BookmarkKeyListEnvelopeFromJson(Map<String, dynamic> json) => BookmarkKeyListEnvelope(
  success: json['success'] as bool,
  data: (json['data'] as List<dynamic>).map((e) => BookmarkKey.fromJson(e as Map<String, dynamic>)).toList(),
  error: json['error'],
);

Map<String, dynamic> _$BookmarkKeyListEnvelopeToJson(BookmarkKeyListEnvelope instance) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};
