// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content_changes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContentChanges _$UserContentChangesFromJson(Map<String, dynamic> json) => UserContentChanges(
  decks: (json['decks'] as List<dynamic>).map((e) => UserDeck.fromJson(e as Map<String, dynamic>)).toList(),
  cards: (json['cards'] as List<dynamic>).map((e) => UserCard.fromJson(e as Map<String, dynamic>)).toList(),
  cursor: json['cursor'] as String,
  hasMore: json['hasMore'] as bool,
  urlsExpireAt: json['urlsExpireAt'] as String,
);

Map<String, dynamic> _$UserContentChangesToJson(UserContentChanges instance) => <String, dynamic>{
  'decks': instance.decks,
  'cards': instance.cards,
  'cursor': instance.cursor,
  'hasMore': instance.hasMore,
  'urlsExpireAt': instance.urlsExpireAt,
};
