// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkEnvelope _$BookmarkEnvelopeFromJson(Map<String, dynamic> json) =>
    BookmarkEnvelope(
      success: json['success'] as bool,
      data: Bookmark.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$BookmarkEnvelopeToJson(BookmarkEnvelope instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };
