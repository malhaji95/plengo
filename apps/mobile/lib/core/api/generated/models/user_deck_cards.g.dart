// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_deck_cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDeckCards _$UserDeckCardsFromJson(Map<String, dynamic> json) => UserDeckCards(
  deck: UserDeck.fromJson(json['deck'] as Map<String, dynamic>),
  cards: (json['cards'] as List<dynamic>).map((e) => UserCard.fromJson(e as Map<String, dynamic>)).toList(),
  urlsExpireAt: json['urlsExpireAt'] as String,
);

Map<String, dynamic> _$UserDeckCardsToJson(UserDeckCards instance) => <String, dynamic>{
  'deck': instance.deck,
  'cards': instance.cards,
  'urlsExpireAt': instance.urlsExpireAt,
};
