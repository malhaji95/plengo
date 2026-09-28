// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkKey _$BookmarkKeyFromJson(Map<String, dynamic> json) =>
    BookmarkKey(itemType: $enumDecode(_$BookmarkItemTypeEnumMap, json['itemType']), itemId: json['itemId'] as String);

Map<String, dynamic> _$BookmarkKeyToJson(BookmarkKey instance) => <String, dynamic>{
  'itemType': instance.itemType,
  'itemId': instance.itemId,
};

const _$BookmarkItemTypeEnumMap = {
  BookmarkItemType.question: 'question',
  BookmarkItemType.flashcard: 'flashcard',
  BookmarkItemType.userCard: 'user_card',
  BookmarkItemType.deck: 'deck',
};
