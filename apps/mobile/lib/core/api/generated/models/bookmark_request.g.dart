// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkRequest _$BookmarkRequestFromJson(Map<String, dynamic> json) =>
    BookmarkRequest(
      itemType: $enumDecode(_$BookmarkRequestItemTypeEnumMap, json['itemType']),
      itemId: json['itemId'] as String,
    );

Map<String, dynamic> _$BookmarkRequestToJson(BookmarkRequest instance) =>
    <String, dynamic>{
      'itemType': _$BookmarkRequestItemTypeEnumMap[instance.itemType]!,
      'itemId': instance.itemId,
    };

const _$BookmarkRequestItemTypeEnumMap = {
  BookmarkRequestItemType.question: 'question',
  BookmarkRequestItemType.flashcard: 'flashcard',
  BookmarkRequestItemType.userCard: 'user_card',
  BookmarkRequestItemType.deck: 'deck',
};
