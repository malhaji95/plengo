// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_cards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeckCards _$DeckCardsFromJson(Map<String, dynamic> json) => DeckCards(
  deck: StudentDeck.fromJson(json['deck'] as Map<String, dynamic>),
  cards: (json['cards'] as List<dynamic>)
      .map((e) => StudentCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  urlsExpireAt: json['urlsExpireAt'] as String,
);

Map<String, dynamic> _$DeckCardsToJson(DeckCards instance) => <String, dynamic>{
  'deck': instance.deck,
  'cards': instance.cards,
  'urlsExpireAt': instance.urlsExpireAt,
};
