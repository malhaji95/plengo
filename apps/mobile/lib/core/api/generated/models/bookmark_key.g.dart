// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkKey _$BookmarkKeyFromJson(Map<String, dynamic> json) => BookmarkKey(
  itemType: $enumDecode(_$BookmarkKeyItemTypeEnumMap, json['itemType']),
  itemId: json['itemId'] as String,
);

Map<String, dynamic> _$BookmarkKeyToJson(BookmarkKey instance) =>
    <String, dynamic>{
      'itemType': _$BookmarkKeyItemTypeEnumMap[instance.itemType]!,
      'itemId': instance.itemId,
    };

const _$BookmarkKeyItemTypeEnumMap = {
  BookmarkKeyItemType.question: 'question',
  BookmarkKeyItemType.flashcard: 'flashcard',
  BookmarkKeyItemType.userCard: 'user_card',
  BookmarkKeyItemType.deck: 'deck',
};
