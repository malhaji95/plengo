// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark.dart';

part 'bookmark_list.g.dart';

@JsonSerializable()
class BookmarkList {
  const BookmarkList({
    required this.items,
    required this.urlsExpireAt,
  });
  
  factory BookmarkList.fromJson(Map<String, Object?> json) => _$BookmarkListFromJson(json);
  
  final List<Bookmark> items;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$BookmarkListToJson(this);
}
