// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => Bookmark(
  id: json['id'] as String,
  itemType: $enumDecode(_$BookmarkItemTypeEnumMap, json['itemType']),
  itemId: json['itemId'] as String,
  createdAt: json['createdAt'] as String,
  locked: json['locked'] as bool,
  available: json['available'] as bool,
  titleAr: json['titleAr'] as String?,
  subjectId: json['subjectId'] as String?,
  subjectNameAr: json['subjectNameAr'] as String?,
  question: json['question'] == null
      ? null
      : StudentQuestion.fromJson(json['question'] as Map<String, dynamic>),
  deck: json['deck'] == null
      ? null
      : StudentDeck.fromJson(json['deck'] as Map<String, dynamic>),
  card: json['card'] == null
      ? null
      : StudentCard.fromJson(json['card'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BookmarkToJson(Bookmark instance) => <String, dynamic>{
  'id': instance.id,
  'itemType': _$BookmarkItemTypeEnumMap[instance.itemType]!,
  'itemId': instance.itemId,
  'createdAt': instance.createdAt,
  'locked': instance.locked,
  'available': instance.available,
  'titleAr': instance.titleAr,
  'subjectId': instance.subjectId,
  'subjectNameAr': instance.subjectNameAr,
  'question': instance.question,
  'deck': instance.deck,
  'card': instance.card,
};

const _$BookmarkItemTypeEnumMap = {
  BookmarkItemType.question: 'question',
  BookmarkItemType.flashcard: 'flashcard',
  BookmarkItemType.userCard: 'user_card',
  BookmarkItemType.deck: 'deck',
};
