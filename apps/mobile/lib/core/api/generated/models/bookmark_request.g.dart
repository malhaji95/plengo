// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkRequest _$BookmarkRequestFromJson(Map<String, dynamic> json) => BookmarkRequest(
  itemType: $enumDecode(_$BookmarkItemTypeEnumMap, json['itemType']),
  itemId: json['itemId'] as String,
);

Map<String, dynamic> _$BookmarkRequestToJson(BookmarkRequest instance) => <String, dynamic>{
  'itemType': instance.itemType,
  'itemId': instance.itemId,
};

const _$BookmarkItemTypeEnumMap = {
  BookmarkItemType.question: 'question',
  BookmarkItemType.flashcard: 'flashcard',
  BookmarkItemType.userCard: 'user_card',
  BookmarkItemType.deck: 'deck',
};
