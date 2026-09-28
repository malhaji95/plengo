// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark_item_type.dart';

part 'bookmark_key.g.dart';

@JsonSerializable()
class BookmarkKey {
  const BookmarkKey({required this.itemType, required this.itemId});

  factory BookmarkKey.fromJson(Map<String, Object?> json) => _$BookmarkKeyFromJson(json);

  final BookmarkItemType itemType;
  final String itemId;

  Map<String, Object?> toJson() => _$BookmarkKeyToJson(this);
}
