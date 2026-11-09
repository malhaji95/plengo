// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_items_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineItemsPage _$OfflineItemsPageFromJson(Map<String, dynamic> json) =>
    OfflineItemsPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => OfflineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      urlsExpireAt: json['urlsExpireAt'] as String,
    );

Map<String, dynamic> _$OfflineItemsPageToJson(OfflineItemsPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'urlsExpireAt': instance.urlsExpireAt,
    };
