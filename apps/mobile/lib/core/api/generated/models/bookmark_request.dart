// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bookmark_item_type.dart';

part 'bookmark_request.g.dart';

@JsonSerializable()
class BookmarkRequest {
  const BookmarkRequest({required this.itemType, required this.itemId});

  factory BookmarkRequest.fromJson(Map<String, Object?> json) => _$BookmarkRequestFromJson(json);

  final BookmarkItemType itemType;
  final String itemId;

  Map<String, Object?> toJson() => _$BookmarkRequestToJson(this);
}
