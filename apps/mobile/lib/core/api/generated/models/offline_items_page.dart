// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_item.dart';

part 'offline_items_page.g.dart';

@JsonSerializable()
class OfflineItemsPage {
  const OfflineItemsPage({required this.items, required this.nextCursor, required this.urlsExpireAt});

  factory OfflineItemsPage.fromJson(Map<String, Object?> json) => _$OfflineItemsPageFromJson(json);

  final List<OfflineItem> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$OfflineItemsPageToJson(this);
}
