// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkList _$BookmarkListFromJson(Map<String, dynamic> json) => BookmarkList(
  items: (json['items'] as List<dynamic>).map((e) => Bookmark.fromJson(e as Map<String, dynamic>)).toList(),
  nextCursor: json['nextCursor'] as String?,
  urlsExpireAt: json['urlsExpireAt'] as String,
);

Map<String, dynamic> _$BookmarkListToJson(BookmarkList instance) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'urlsExpireAt': instance.urlsExpireAt,
};
